-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local Logger = require("lua/Logger")

-- Wrapper of the LuaGuiElement class from Factorio.
--
-- This wrapper aims at attaching callbacks for gui events (ex: on_gui_click) to each element, and any other data.
-- The framework ensures that a LuaGuiElement has a unique wrapper object.
--
-- Stored in global: yes
--
-- Fields:
-- * rawElement: Wrapper LuaGuiElement object.
-- * callbacksIndex: index of the Callbacks object used by this object.
--
-- RO properties:
-- * add: Wraps rawElement.add(...)
-- * on_click: method to execute when on_gui_click is triggered (can be nil).
--
local GuiElement = {
    -- Function to register callbacks.
    newCallbacks = nil, -- implemented later

    -- Function to call in Factorio's on_gui_click event.
    on_gui_click = nil, -- implemented later

    -- Function to call in Factorio's on_load event.
    on_load = nil, -- implemented later

    -- Function to call in Factorio's on_init event.
    on_init = nil, -- implemented later

    -- Function to create/retrieve the wrapper of a LuaGuiElement instance.
    wrap = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Set containing all the registered callbacks (not persistent between load/saves).
    CallbacksSet = {},

    -- List of properties forwarded by a GuiElement from its associated Callbacks instance.
    ForwardedCallbacks = {
        on_click = true,
    },

    -- Map of GuiElement, indexed by the associated LuaGuiElement.index (stored in global).
    Map = {},

    -- Metatable of the GuiElement class.
    Metatable = {
        __index = nil, -- implemented later
    },

    -- Function creating a new GuiElement.
    newGuiElement = nil, -- implemented later

    -- Constant values returned by Metatable.__index
    RawIndex = {
        add = nil, -- implemented later
    },
}

-- Registers a new Callbacks object
--
-- A Callbacks object has an index field, which must be unique in the whole program. This index can be on any type
-- storable in global.
--
-- A Callbacks object optionally contains function pointers
--
-- Args:
-- * object: the new callback (ex: {index="someUniqueName",on_click=aFunction,...})
--
function GuiElement.newCallbacks(object)
    local index = object.index
    if not Impl.CallbacksSet[index] then
        Impl.CallbacksSet[index] = object
    else
        Logger.error("Duplicate callbacks registered in GuiElement")
    end
end

function GuiElement.on_gui_click(event)
    local element = GuiElement.wrap(event.element)
    if element.on_click then
        element:on_click(event)
    end
end

function GuiElement.on_load()
    Impl.Map = global.guiElementMap
    for _,guiElement in pairs(Impl.Map) do
        setmetatable(guiElement,Impl.Metatable)
    end
end

function GuiElement.on_init()
    global.guiElementMap = Impl.Map
end

-- Gets the wrapper of a LuaGuiElement, or create it.
--
-- Args:
-- * rawElement: LuaGuiElement to wrap.
--
-- Returns: the unique GuiElement object wrapping the argument.
function GuiElement.wrap(rawElement)
    local result = nil
    if rawElement then
        result = Impl.Map[rawElement.index]
        if not result then
            result = Impl.newGuiElement({rawElement= rawElement})
        end
    end
    return result
end

-- Creates a new GuiElement object, and updates the internal mapping.
--
-- Args:
-- * object: table to turn into the GuiElement.
--
-- Returns: A new GuiElement wrapping the argument.
--
function Impl.newGuiElement(object)
    setmetatable(object, Impl.Metatable)
    Impl.Map[object.rawElement.index] = object
    return object
end

-- Wraps LuaGuiElement.add()
--
-- Args:
-- * self: GuiElement instance.
-- * rawArgs: Arguments forwarded to LuaGuiElement.add(...).
-- * object: table to turn into the GuiElement.
--
-- Returns: The new GuiElement.
function Impl.RawIndex.add(self, rawArgs, object)
    local result = object or {}
    local rawElement = self.rawElement.add(rawArgs)
    result.rawElement = rawElement
    return Impl.newGuiElement(result)
end

function Impl.Metatable.__index(self, fieldName)
    local result = Impl.RawIndex[fieldName]
    if not result then
        if Impl.ForwardedCallbacks[fieldName] and self.callbacksIndex then
            local callbacks = Impl.CallbacksSet[self.callbacksIndex]
            if callbacks then
                result = callbacks[fieldName]
            else
                Logger.error("Unknown GuiElement callbacks (index: " .. self.callbacksIndex .. ")")
            end
        end
    end
    return result
end

return GuiElement