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
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")

local cLogger = ClassLogger.new{className = "GuiMenuWindow"}

local GuiConstructorArgs
local HideButton
local Metatable

-- Instanciated GUI of a GuiMenuWindow.
--
-- RO Fields:
-- * controller: MenuWindow. Owner of this GUI.
-- * frame: LuaGuiElement. Top-level element owned by this GUI.
-- * hideButton: HideButton of this player (in menuFrame).
-- * parent: LuaGuiElement. Element containing this GUI.
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
        local controller = cLogger:assertField(object, "controller")
        local parent = cLogger:assertField(object, "parent")

        object.frame = GuiMaker.run(parent, GuiConstructorArgs)
        object.frame.location = {0,0}
        object.frame.style.maximal_height = 50

        object.hideButton = HideButton.new{
            controller = controller,
            rawElement = object.frame.hideButton,
        }

        setmetatable(object, Metatable)
        object:updateAppMenu()
        return object
    end,

    -- Restores the metatable of a GuiMenuWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        HideButton.setmetatable(object.hideButton)
    end,
}

-- Metatable of the GuiMenuWindow class.
Metatable = {
    __index = {
        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.hideButton:close()
        end,

        -- Handles modifications of the controller's appMenu field.
        --
        -- Args:
        -- * self: GuiMenuWindow.
        --
        updateAppMenu = function(self)
            local appMenu = rawget(self.controller, "appMenu")
            if appMenu then
                appMenu:open(self.frame.appFlow)
            end
        end,
    }
}

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
