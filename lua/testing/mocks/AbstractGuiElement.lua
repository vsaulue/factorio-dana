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

local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local GuiLocation = require("lua/testing/mocks/GuiLocation")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger
local checkAutoCenterConditions
local destroyImpl
local lastIndex
local make
local makeUniqueIndex
local Metatable
local Subtypes

-- Base class for mocks of LuaGuiElement.
--
-- See https://lua-api.factorio.com/1.0.0/LuaGuiElement.html.
--
-- Inherits from CommonMockObject.
--
-- Implemented fields & methods:
-- * add()
-- * auto_center
-- * caption
-- * children
-- * clear()
-- * destroy()
-- * direction
-- * force_auto_center()
-- * index
-- * location
-- * name
-- * parent
-- * player_index
-- * type
-- * style
-- * visible
-- + CommonMockObject properties.
--
-- Other internal fields:
-- * childrenByName[string]: AbstractGuiElement. Map of child elements, indexed by their names.
-- * childrenHasLocation: boolean. True if children have a `location` field (like LuaGui:screen).
--
local AbstractGuiElement = {
    -- Base constructor for all types inheriting from AbstractGuiElement.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement from Factorio.
    -- * mockArgs: table. May contain the following fields:
    -- **  childrenHasLocation: boolean.
    -- **  player_index: int. Ignored if parent is set.
    -- **  parent: AbstractGuiElement. If not set, player_index is mandatory.
    -- * metatable: Metatable to set to the new object.
    --
    -- Returns: The new AbstractGuiElement object.
    --
    abstractMake = function(args, mockArgs, metatable)
        local _type = cLogger:assertField(args, "type")

        local player_index
        local parent = mockArgs.parent
        if parent then
            player_index = parent.player_index
        else
            player_index = mockArgs.player_index
            cLogger:assert(player_index, "mockArgs must contain either 'player_index' or 'parent'.")
        end

        local style = {}
        if args.style then
            cLogger:assert(type(args.style) == "string", "Constructor: invalid style value (string required).")
            style.name = args.style
        end

        local enabled = true
        if args.enabled ~= nil then
            enabled = not not args.enabled
        end

        local location = nil
        if parent and MockObject.getData(parent).childrenHasLocation then
            location = {x=0, y=0}
        end

        local name = args.name
        if name then
            cLogger:assert(type(name) == "string", "Constructor: invalid name (string required).")
        end

        local data = {
            auto_center = false,
            caption = args.caption,
            children = {},
            childrenByName = {},
            childrenHasLocation = not not mockArgs.childrenHasLocation,
            enabled = enabled,
            index = makeUniqueIndex(),
            location = location,
            name = name,
            parent = parent,
            player_index = player_index,
            type = _type,
            style = style,
            visible = not not args.visible,
        }
        return CommonMockObject.make(data, metatable or Metatable)
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
        cLogger:assert(subtype, "Unknown type: " .. tostring(_type))
        return subtype.make(args, parent, player_index)
    end,

    -- Metatable of the AbstractGuiElement class.
    Metatable = CommonMockObject.Metatable:makeSubclass{
        className = "AbstractGuiElement",

        getters = {
            add = function(self)
                return function(childArgs)
                    local data = MockObject.getData(self, "add")
                    local child = make(childArgs, {parent = self})
                    local childName = child.name
                    if childName then
                        local childrenByName = data.childrenByName
                        cLogger:assert(not childrenByName[childName], "Duplicate name in parent: " .. childName)
                        data.childrenByName[childName] = child
                    end
                    table.insert(data.children, child)
                    return child
                end
            end,

            auto_center = MockGetters.validTrivial("auto_center"),

            -- Note: should return a deep-copy.
            caption = MockGetters.validTrivial("caption"),

            clear = function(self)
                return function()
                    local data = MockObject.getData(self, "clear")
                    for _,child in ipairs(data.children) do
                        destroyImpl(child)
                    end
                    data.children = {}
                    data.childrenByName = {}
                end
            end,

            -- Note: should return a shallow-copy.
            children = MockGetters.validTrivial("children"),

            destroy = function(self)
                return function()
                    local data = MockObject.getData(self, "destroy")
                    local parent = data.parent
                    if parent then
                        local parentData = MockObject.getData(parent)
                        local index = 1
                        local child = parentData.children[1]
                        while child and child ~= self do
                            index = index + 1
                            child = parentData.children[index]
                        end
                        cLogger:assert(child, "Corrupted parent <-> child relationship.")
                        table.remove(parentData.children, index)
                        if data.name then
                            parentData.childrenByName[data.name] = nil
                        end
                        destroyImpl(self)
                    else
                        cLogger:error("Can't destroy root element.")
                    end
                end
            end,

            force_auto_center = function(self)
                return function()
                    local data = MockObject.getData(self, "force_auto_center")
                    checkAutoCenterConditions(data)
                    -- Note: the Mock API doesn't have the concept of screen yet.
                    -- Just throwing some non-zero position for now.
                    data.location.x = 12
                    data.location.y = 12
                    data.auto_center = true
                end
            end,

            enabled = MockGetters.validTrivial("enabled"),
            index = MockGetters.validTrivial("index"),
            location = MockGetters.validDeepCopy("location"),
            name = MockGetters.validTrivial("name"),
            parent = MockGetters.validTrivial("parent"),
            player_index = MockGetters.validTrivial("player_index"),
            style = MockGetters.validTrivial("style"),
            type = MockGetters.validTrivial("type"),
            visible = MockGetters.validTrivial("visible"),
        },

        fallbackGetter = function(self, index)
            local success = (type(index) == "string") and index ~= "valid"
            local result = nil
            if success then
                local data = MockObject.getData(self, index)
                result = data.childrenByName[index]
            end
            return success,result
        end,

        setters = {
            auto_center = function(self, value)
                local data = MockObject.getData(self, "auto_center")
                checkAutoCenterConditions(data)
                data.auto_center = not not value
            end,

            caption = function(self, value)
                local data = MockObject.getData(self, "caption")
                -- Note: needs a LocalisedString check & a deep copy.
                data.caption = value
            end,

            enabled = function(self, value)
                local data = MockObject.getData(self, "enabled")
                data.enabled = not not value
            end,

            location = function(self, value)
                local data = MockObject.getData(self, "location")
                local location = data.location
                if location then
                    GuiLocation.parse(data.location, value)
                end
            end,

            style = function(self, value)
                local data = MockObject.getData(self, "style")
                cLogger:assert(type(value) == "string", "Invalid write at 'style': string required.")
                data.style = {
                    name = value,
                }
            end,

            visible = function(self, value)
                local data = MockObject.getData(self, "visible")
                data.visible = not not value
            end,
        },
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

cLogger = AbstractGuiElement.Metatable.cLogger

-- Checks that an AbstractGuiElement can be auto centered.
--
-- Args:
-- * selfData: table. Mock data of the AbstractGuiElement.
--
checkAutoCenterConditions = function(selfData)
    cLogger:assert(selfData.location, "Cannot call force_auto_center(): parent does not allow location.")
    cLogger:assert(selfData.type == "frame", "Cannot call force_auto_center(): requires type == 'frame'.")
end

-- Invalidates an AbstractGuiElement, and all its children.
--
-- Args:
-- * self: AbstractGuiElement object.
--
destroyImpl = function(self)
    local data = MockObject.getDataIfValid(self)
    local children = data.children
    for _,child in ipairs(children) do
        destroyImpl(child)
    end
    MockObject.invalidate(self)
end

make = AbstractGuiElement.make

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

-- Map[type] -> ClassTable.
--
-- Map giving the appropriate class table according to the value of the "type" field.
--
Subtypes = {}

return AbstractGuiElement
