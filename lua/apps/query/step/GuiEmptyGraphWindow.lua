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

local AbstractGui = require("lua/gui/AbstractGui")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local MetaUtils = require("lua/class/MetaUtils")

local BackButton
local Metatable

-- Instanciated GUI of an EmptyGraphWindow.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller (override): EmptyGraphWindow.
-- * frame: LuaGuiElement. Top-level frame owned by this GUI.
-- + AbstractGui.
--
local GuiEmptyGraphWindow = ErrorOnInvalidRead.new{
    -- Creates a new GuiEmptyGraphWindow object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiEmptyGraphWindow. The argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)

        local frame = object.parent.add{
            type = "frame",
            direction = "vertical",
            caption = {"dana.apps.query.emptyGraphWindow.title"},
        }
        object.frame = frame

        frame.add{
            type = "label",
            caption = {"dana.apps.query.emptyGraphWindow.description"},
        }
        frame.add{
            type = "line",
            direction = "horizontal",
        }
        if frame.location then
            frame.force_auto_center()
        end
        object.backButton = BackButton.new{
            controller = object.controller,
            rawElement = object.frame.add{
                type = "button",
                caption = {"gui.cancel"},
                style = "back_button",
            },
        }

        return object
    end,

    -- Restores the metatable of a GuiEmptyGraphWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        BackButton.setmetatable(object.backButton)
    end,
}

-- Metatable of the GuiEmptyGraphWindow class
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.backButton:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.frame.valid
        end,
    },
})

-- Button to go back to the previous window.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * controller: EmptyGraphWindow. Controller owning this button.
--
BackButton = GuiElement.newSubclass{
    className = "EmptyGraphWindow/BackButton",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller.appInterface:popStepWindow()
        end,
    }
}

return GuiEmptyGraphWindow
