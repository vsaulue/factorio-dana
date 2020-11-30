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

local Metatable
local OpenGuiButton

-- Instanciated GUI of a ModGuiButton.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * button: OpenGuiButton. Button of this GUI.
-- * controller (override): ModGuiButton.
-- + AbstractGui.
--
local GuiModGuiButton = ErrorOnInvalidRead.new{
    -- Creates a new GuiModGuiButton object.
    --
    -- Args:
    -- * object: table. Required fields: same as AbstractGui.
    --
    -- Returns: GuiModGuiButton. The `object` argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)
        object.button = OpenGuiButton.new{
            controller = object.controller,
            rawElement = object.parent.add{
                type = "sprite-button",
                sprite = "dana-shortcut-icon",
                style = "mod_gui_button",
                tooltip = {"dana.longName"},
            },
        }
        return object
    end,

    -- Restores the metatable of a GuiModGuiButton, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        OpenGuiButton.setmetatable(object.button)
    end,
}

-- Metatable of the GuiModGuiButton class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            self.button.rawElement.destroy()
            self.button:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.button.rawElement.valid
        end,
    },
})

-- Button to open Dana's GUI.
--
-- RO Fields:
-- * controller: ModGuiButton.
--
OpenGuiButton = GuiElement.newSubclass{
    mandatoryFields = {"controller"},
    className = "GuiModGuiButton/OpenGuiButton",
    __index = {
        onClick = function(self)
            self.controller.playerCtrlInterface:show()
        end,
    },
}

return GuiModGuiButton
