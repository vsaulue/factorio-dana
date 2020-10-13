-- This file is part of Dana.
-- Copyright (C) 2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
--
-- Dana is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- Dana is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with Dana.  If not, see <https://www.gnu.org/licenses/>.

local ClassLogger = require("lua/logger/ClassLogger")

local cLogger = ClassLogger.new{className = "AbstractGuiElement"}

local DataIndex
local destroyImpl
local ForwardedIndex
local getValidData
local lastIndex
local makeUniqueIndex
local Metatable
local MethodFactory
local Setters
local Subtypes

-- Base class for mocks of LuaGuiElement.
--
-- See https://lua-api.factorio.com/1.0.0/LuaGuiElement.html.
--
-- Implemented fields & methods:
-- * add()
-- * caption
-- * children
-- * clear()
-- * destroy()
-- * direction
-- * index
-- * parent
-- * player_index
-- * type
-- * style
-- * valid
-- * visible
--
-- The mock object doesn't store these values directly into the root table. They are "hidden"
-- in a subtable. This enables to perform some checking on all read/write operations with __index & __newindex.
--
local AbstractGuiElement = {
    -- Base constructor for all types inheriting from AbstractGuiElement.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement from Factorio.
    -- * player_index: int. Index of the player owning the new element.
    -- * parent: AbstractGuiElement. Parent element that will own the new element (may be nil).
    -- * metatable: Metatable to set to the new object.
    --
    -- Returns: The new AbstractGuiElement object.
    --
    abstractMake = function(args, player_index, parent, metatable)
        local _type = cLogger:assertField(args, "type")
        cLogger:assert(player_index, "Constructor: missing 'player_index' argument.")
        if parent then
            cLogger:assert(parent.player_index == player_index, "Parent & child have different player_index.")
        end

        local result = {
            [DataIndex] = {
                caption = args.caption,
                children = {},
                index = makeUniqueIndex(),
                parent = parent,
                player_index = player_index,
                type = _type,
                style = {},
                visible = not not args.visible,
            },
        }
        setmetatable(result, metatable or Metatable)
        return result
    end,

    -- Gets the internal table holding the unprotected values of the mock.
    --
    -- Args:
    -- * self: AbstractGuiElement object.
    --
    -- Returns: The internal table containing the field's value of the given element (nil if invalid).
    --
    getDataIfValid = function(self)
        return rawget(self, DataIndex)
    end,

    -- Creates a new LuaGuiElement object (with the appropriate subtype).
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * player_index: int. Index of the player owning the new element.
    -- * parent: AbstractGuiElement. Parent element that will own the new element (may be nil).
    --
    -- Returns: The new LuaGuiElement object.
    --
    make = function(args, parent, player_index)
        local _type = cLogger:assertField(args, "type")
        local subtype = Subtypes[_type]
        cLogger:assert(subtype, "Unknown type: " .. tostring(subtype))
        return subtype.make(args, parent, player_index)
    end,

    -- Metatable of the AbstractGuiElement class.
    Metatable = {
        -- Flag for SaveLoadTester.
        autoLoaded = true,

        __index = function(self, index)
            if index == "valid" then
                return rawget(self, DataIndex) ~= nil
            end

            local data = getValidData(self)

            if ForwardedIndex[index] then
                return data[index]
            end

            local methodMaker = MethodFactory[index]
            if methodMaker then
                return methodMaker(self)
            end

            cLogger:error("Invalid read at: " .. tostring(index) .. ".")
        end,

        __newindex = function(self, index, value)
            local setter = Setters[index]
            if setter then
                setter(getValidData(self), value)
            else
                cLogger:error("Invalid write at: " .. tostring(index) .. ".")
            end
        end,
    },

    -- Registers a new subtype for the factory.
    --
    -- Args:
    -- * className: Name of the type (corresponding to the "type" value of the instanciated LuaGuiElement).
    -- * classTable: Table containing the make() function used to create the class.
    --
    registerClass = function(className, classTable)
        cLogger:assert(not Subtypes[className], "Duplicate subtype identifier: " .. tostring(className))
        Subtypes[className] = classTable
    end,
}

-- Hidden key to access the table containing the element's fields.
DataIndex = {}

-- Invalidates an AbstractGuiElement, and all its children.
--
-- Args:
-- * self: AbstractGuiElement object.
--
destroyImpl = function(self)
    local children = self[DataIndex].children
    for _,child in ipairs(children) do
        destroyImpl(child)
    end
    self[DataIndex] = nil
end

-- Name of the fields which can directly be returned from the internal table via __index.
ForwardedIndex = {
    caption = true,  -- Note: should return a deep-copy.
    children = true, -- Note: should return a deep-copy.
    index = true,
    parent = true,
    player_index = true,
    style = true,
    type = true,
    visible = true,
}

-- Gets the internal table if the object is valid.
--
-- Args:
-- * self: AbstractGuiElement object.
--
-- Returns: The internal table of the argument.
--
getValidData = function(self)
    local result = rawget(self, DataIndex)
    cLogger:assert(result, "Object is not valid.")
    return result
end

-- Last generated index by the LuaGuiElement mock library.
lastIndex = 0

-- Makes a unique index for AbstractGuiElement.index.
--
-- Returns: int.
--
makeUniqueIndex = function()
    lastIndex = lastIndex + 1
    return lastIndex
end

Metatable = AbstractGuiElement.Metatable

-- Map[methodName] -> function. Table containing callbacks used to generate methods.
--
-- Since methods are called as object.method(), and not object:method(), the mocking framework
-- must return a dedicated closure, instead of a generic method usable with any instance.
--
MethodFactory = {
    add = function(self)
        return function(childArgs)
            local data = getValidData(self)
            local child = AbstractGuiElement.make(childArgs, data.player_index, self)
            table.insert(data.children, child)
            return child
        end
    end,

    clear = function(self)
        return function()
            local data = getValidData(self)
            for _,child in ipairs(data.children) do
                destroyImpl(child)
            end
            data.children = {}
        end
    end,

    destroy = function(self)
        return function()
            local data = getValidData(self)
            local parent = data.parent
            if parent then
                local index = 1
                local child = parent.children[1]
                while child and child ~= self do
                    index = index + 1
                    child = parent.children[index]
                end
                cLogger:assert(child, "Corrupted parent <-> child relationship.")
                table.remove(parent.children, index)
            end
            destroyImpl(self)
        end
    end,
}

-- Map[fieldName] -> function. Setter to call in __newindex for a given field name.
Setters = {
    caption = function(data, value)
        -- Note: needs a LocalisedString check & a deep copy.
        data.caption = value
    end,

    visible = function(data, value)
        data.visible = not not value
    end,
}

-- Map[type] -> ClassTable.
--
-- Map giving the appropriate class table according to the value of the "type" field.
--
Subtypes = {}

return AbstractGuiElement
