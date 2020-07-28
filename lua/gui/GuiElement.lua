-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "GuiElement"}

local assertClassParametersField
local GuiElementMap
local Metatable
local new
local recursiveUnbind

-- Wrapper of the LuaGuiElement class from Factorio.
--
-- This wrapper aims at attaching callbacks for gui events (ex: on_gui_click) to each element, and any other data.
-- The framework ensures that a LuaGuiElement has a unique wrapper object.
--
-- Stored in global: yes
--
-- Fields:
-- * rawElement: Wrapper LuaGuiElement object.
--
-- Abstract methods:
-- * on_click: method to execute when on_gui_click is triggered (can be nil).
--
local GuiElement = ErrorOnInvalidRead.new{
    -- Unbinds all child elements of a LuaGuiElement object, then clear all its children.
    --
    -- Args:
    -- * rawElement: LuaGuiElement whose children will be deleted.
    --
    clear = function(rawElement)
        for _,rawChild in ipairs(rawElement.children) do
            recursiveUnbind(rawChild)
        end
        rawElement.clear()
    end,

    -- Destroy a LuaGuiElement, and unbinds all GuiElement objects associated to it or its children.
    --
    -- Args:
    -- * rawElement: LuaGuiElement (Factorio object) to destroy.
    --
    destroy = function(rawElement)
        recursiveUnbind(rawElement)
        rawElement.destroy()
    end,

    -- Creates a new class inheriting from GuiElement.
    --
    -- Args:
    -- * classParameters: a table with the following fields:
    -- **  className: Name of the new class.
    -- **  mandatoryFields: Lua array of required fields to check in the constructor.
    -- **  __index: Table to used as the metafield of the same name.
    --
    -- Returns: a class table (with new/setmetatable functions).
    --
    newSubclass = function(classParameters)
        local subclassName = assertClassParametersField(classParameters, "className")
        local mandatoryFields = assertClassParametersField(classParameters, "mandatoryFields")
        local subclassIndex = assertClassParametersField(classParameters, "__index")

        local subclassMetatable = {
            __index = subclassIndex,
        }
        setmetatable(subclassIndex, { __index = Metatable.__index })
        local subclassLogger = ClassLogger.new{className = subclassName}

        local result = ErrorOnInvalidRead.new{
            -- Creates a new instance of the specified subclass.
            new = function(object)
                for _,fieldName in ipairs(mandatoryFields) do
                    subclassLogger:assertField(object, fieldName)
                end
                return new(object, subclassMetatable)
            end,

            -- Restores the metatable of a table of the specified subclass.
            setmetatable = function(object)
                setmetatable(object, subclassMetatable)
            end,
        }
        return result
    end,

    -- Function to call in Factorio's on_gui_checked_state_changed event.
    --
    -- Args:
    -- * event: Event object sent by Factorio.
    --
    on_gui_checked_state_changed = function(event)
        local element = GuiElementMap[event.player_index][event.element.index]
        if element then
            element:onCheckedStateChanged(event)
        end
    end,

    -- Function to call in Factorio's on_gui_click event.
    --
    -- Args:
    -- * event: Event object sent by Factorio.
    --
    on_gui_click = function(event)
        local element = GuiElementMap[event.player_index][event.element.index]
        if element then
            local onClick = element.onClick
            if onClick then
                onClick(element, event)
            end
        end
    end,

    -- Function to call in Factorio's on_gui_elem_changed event.
    --
    -- Args:
    -- * event: Event object sent by Factorio.
    --
    on_gui_elem_changed = function(event)
        local element = GuiElementMap[event.player_index][event.element.index]
        if element then
            element:onElemChanged(event)
        end
    end,

    -- Function to call in Factorio's on_gui_text_changed event.
    --
    -- Args:
    -- * event: Event object sent by Factorio.
    --
    on_gui_text_changed = function(event)
        local element = GuiElementMap[event.player_index][event.element.index]
        if element then
            element:onTextChanged(event)
        end
    end,

    -- Function to call in Factorio's on_load event.
    --
    on_load = function()
        GuiElementMap = global.guiElementMap
    end,

    -- Function to call in Factorio's on_init event.
    --
    on_init = function()
        global.guiElementMap = GuiElementMap
        for playerIndex in pairs(game.players) do
            GuiElementMap[playerIndex] = {}
        end
    end,

    -- Function to call in Factorio's on_player_created event.
    --
    -- Args:
    -- * event: Event object sent by Factorio.
    --
    on_player_created = function(event)
        GuiElementMap[event.player_index] = {}
    end,
}

-- Metatable of the GuiElement class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Callback used when Factorio's on_gui_checked_state_changed is called on the wrapped rawElement.
        --
        -- Args:
        -- * self: GuiElement corresponding to the wrapped LuaGuiElement being clicked.
        -- * event: Event object sent by Factorio.
        --
        onCheckedStateChanged = function(self, event) end,

        -- Callback used when Factorio's on_gui_click is called on the wrapped rawElement.
        --
        -- Args:
        -- * self: GuiElement corresponding to the wrapped LuaGuiElement being clicked.
        -- * event: Event object sent by Factorio.
        --
        onClick = function(self, event) end,

        -- Callback used when Factorio's on_gui_elem_changed is called on the wrapped rawElement.
        --
        -- Args:
        -- * self: GuiElement corresponding to the wrapped LuaGuiElement of the event.
        -- * event: Event object sent by Factorio.
        --
        onElemChanged = function(self, event) end,

        -- Callback used when Factorio's on_gui_text_changed is called on the wrapped rawElement.
        --
        -- Args:
        -- * self: GuiElement corresponding to the wrapped LuaGuiElement of the event.
        -- * event: Event object sent by Factorio.
        --
        onTextChanged = function(self, event) end,
    },
}

-- Checks that a field is present in a ClassParameter object.
--
-- Args:
-- * classParameters: ClassParameter object to check.
-- * fieldName: Field to look for.
--
-- Returns: The value of the specified field.
--
assertClassParametersField = function(classParameters, fieldName)
    local result = classParameters[fieldName]
    if not result then
        cLogger:error("Missing mandatory class parameter '" .. fieldName .. "'.")
    end
    return result
end

-- Map[playerIndex][rawElemIndex] -> GuiElement. Gets the GuiElement wrapping a specific LuaGuiElement.
GuiElementMap = {}

-- Creates a new GuiElement object.
--
-- Args:
-- * object: Table to turn into a GuiElement object.
-- * metatable: Metatable to use.
--
-- Returns: The first argument turned into a GuiElement object.
--
new = function(object, metatable)
    local rawElement = cLogger:assertField(object, "rawElement")
    setmetatable(object, metatable)

    -- Binding
    local index = rawElement.index
    local playerMap = GuiElementMap[rawElement.player_index]
    cLogger:assert(not playerMap[index], "attempt to bind an object twice.")
    playerMap[index] = object

    return object
end

-- Unbinds the GuiElement associated to the argument, or any of its children.
--
-- Args:
-- * rawElement: Parent of the LuaGuiElement hierarchy to unbind.
--
recursiveUnbind = function(rawElement)
    GuiElementMap[rawElement.player_index][rawElement.index] = nil
    for _,rawChild in ipairs(rawElement.children) do
        recursiveUnbind(rawChild)
    end
end

return GuiElement
