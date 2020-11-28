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

local AbstractGui = require("lua/gui/AbstractGui")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")

local GuiConstructorArgs
local HideButton
local Metatable

-- Instanciated GUI of a GuiMenuWindow.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller: MenuWindow.
-- * frame: LuaGuiElement. Top-level element owned by this GUI.
-- * hideButton: HideButton of this player (in menuFrame).
-- + AbstractGui.
--
local GuiMenuWindow = ErrorOnInvalidRead.new{
    -- Creates a new GuiMenuWindow object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiMenuWindow. The `object` argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)

        object.frame = GuiMaker.run(object.parent, GuiConstructorArgs)
        object.frame.location = {0,0}
        object.frame.style.maximal_height = 50

        object.hideButton = HideButton.new{
            controller = object.controller,
            rawElement = object.frame.hideButton,
        }

        object:updateAppMenu()
        return object
    end,

    -- Restores the metatable of a GuiMenuWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        HideButton.setmetatable(object.hideButton)
    end,
}

-- Metatable of the GuiMenuWindow class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.hideButton:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.frame.valid
        end,

        -- Handles modifications of the controller's appMenu field.
        --
        -- Args:
        -- * self: GuiMenuWindow.
        --
        updateAppMenu = function(self)
            if self:sanityCheck() then
                local appMenu = rawget(self.controller, "appMenu")
                if appMenu then
                    appMenu:open(self.frame.appFlow)
                end
            end
        end,
    }
})

-- GuiMaker arguments to build this GUI.
GuiConstructorArgs = {
    type = "frame",
    direction = "horizontal",
    children = {
        {
            type = "button",
            name = "hideButton",
            caption = {"dana.player.leave"},
            style = "red_back_button",
        },{
            type = "line",
            direction = "vertical",
        },{
            type = "flow",
            name = "appFlow",
            direction = "horizontal",
        }
    },
}

-- Button to hide the application of a player.
--
-- Inherits from GuiElement.
--
-- RO field:
-- * player: Player object attached to this GUI.
--
HideButton = GuiElement.newSubclass{
    className = "GuiMenuWindow/HideButton",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller.playerCtrlInterface:hide(false)
        end,
    }
}

return GuiMenuWindow
