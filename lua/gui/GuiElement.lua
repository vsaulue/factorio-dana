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
local Logger = require("lua/logger/Logger")

local cLogger = ClassLogger.new{className = "GuiElement"}

local GuiElementMap = {}

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
    -- Binds the arguement to an API LuaGuiElement.
    --
    -- Args:
    -- * guiElement: GuiElement to bind (its rawElement field contains the API LuaGuiElement).
    --
    bind = function(guiElement)
        local rawElement = cLogger:assertField(guiElement, "rawElement")
        local index = rawElement.index
        cLogger:assert(not GuiElementMap[index], "attempt to bind an object twice.")
        GuiElementMap[index] = guiElement
    end,

    -- Function to call in Factorio's on_gui_click event.
    --
    -- Args:
    -- * event: Event object sent by Factorio.
    --
    on_gui_click = function(event)
        local element = GuiElementMap[event.element.index]
        local onClick = element.onClick
        if onClick then
            onClick(element, event)
        end
    end,

    -- Function to call in Factorio's on_load event.
    --
    on_load = function()
        GuiElementMap = global.guiElementMap
        for _,guiElement in pairs(GuiElementMap) do
            setmetatable(guiElement,Impl.Metatable)
        end
    end,

    -- Function to call in Factorio's on_init event.
    --
    on_init = function()
        global.guiElementMap = GuiElementMap
    end,
}

return GuiElement
