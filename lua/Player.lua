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

local AppController = require("lua/apps/AppController")
local AppResources = require("lua/apps/AppResources")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")

local Metatable
local HideButton
local ShowButton

-- Class holding data associated to a player in this mod.
--
-- Stored in global: yes
--
-- Fields:
-- * appController: AppController object of this player.
-- * force: Force this player belongs to.
-- * rawPlayer: Associated LuaPlayer instance.
-- * graphSurface: LuaSurface used to display graphs to this player.
-- * hideButton: HideButton of this player (in menuFrame).
-- * menuFrame: Top menu displayed when the application is opened.
-- * showButton: ShowButton object owned by this player.
--
-- RO properties:
-- * opened: true if the GUI is opened.
--
local Player = ErrorOnInvalidRead.new{
    -- Creates a new Player object.
    --
    -- Args:
    -- * object: table to turn into the Player object (required fields: force, graphSurface, rawPlayer).
    --
    new = function(object)
        setmetatable(object, Metatable)
        object.opened = false
        -- Open button
        object.showButton = ShowButton.new{
            rawElement = object.rawPlayer.gui.left.add{
                type = "button",
                name = "menuButton",
                caption = "Dana",
            },
            player = object,
        }
        -- Top menu
        object.menuFrame = object.rawPlayer.gui.screen.add{
            type = "frame",
            direction = "horizontal",
            visible = false,
        }
        object.menuFrame.location = {0,0}
        object.menuFrame.style.maximal_height = 50
        object.hideButton = HideButton.new{
            rawElement = object.menuFrame.add{
                type = "button",
                caption = {"dana.player.leave"},
                style = "red_back_button",
            },
            player = object,
        }
        object.menuFrame.add{
            type = "line",
            direction = "vertical",
        }
        --
        object.appController = AppController.new{
            appResources = AppResources.new{
                menuFlow = object.menuFrame.add{
                    type = "flow",
                    direction = "horizontal",
                    name = "appFlow",
                },
                rawPlayer = object.rawPlayer,
                surface = object.graphSurface,
                force = object.force,
            },
        }
        return object
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        HideButton.setmetatable(object.hideButton)
        ShowButton.setmetatable(object.showButton)
        AppController.setmetatable(object.appController)
    end,
}

-- Metatable of the Player class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Function to call when Factorio's on_player_selected_area is triggered for this player.
        --
        -- Args:
        -- * self: Player object.
        -- * event: Factorio event.
        --
        onSelectedArea = function(self, event)
            self.appController.app:onSelectedArea(event)
        end,

        -- Shows Dana's GUI, and moves the player to the drawing surface.
        --
        -- Args:
        -- * self: Player object.
        --
        show = function(self)
            if not self.opened then
                self.opened = true
                self.menuFrame.visible = true
                self.showButton.rawElement.visible = false
                self.appController:show()
            end
        end,

        -- Hides Dana's GUI, and moves the player back to its last position/surface.
        --
        -- Args:
        -- * self: Player object.
        --
        hide = function(self)
            if self.opened then
                self.opened = false
                self.menuFrame.visible = false
                self.showButton.rawElement.visible = true
                self.appController:hide()
            end
        end,
    },
}

-- Button to show the application of a player.
--
-- Inherits from GuiElement.
--
-- RO field:
-- * player: Player object attached to this GUI.
--
ShowButton = GuiElement.newSubclass{
    className = "Player/ShowButton",
    mandatoryFields = {"player"},
    __index = {
        onClick = function(self, event)
            self.player:show()
        end,
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
    className = "Player/HideButton",
    mandatoryFields = {"player"},
    __index = {
        onClick = function(self, event)
            self.player:hide()
        end,
    }
}

return Player
