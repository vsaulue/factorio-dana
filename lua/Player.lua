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
local GraphApp = require("lua/apps/graph/GraphApp")
local GuiElement = require("lua/gui/GuiElement")
local PlayerGui = require("lua/PlayerGui")

local Metatable

-- Class holding data associated to a player in this mod.
--
-- Stored in global: yes
--
-- Fields:
-- * appController: AppController object of this player.
-- * force: Force this player belongs to.
-- * rawPlayer: Associated LuaPlayer instance.
-- * graphSurface: LuaSurface used to display graphs to this player.
-- * previousCharacter: Character of the player before opening the GUI.
-- * previousControllerType: Controller of the player before opening the GUI.
-- * previousPosition: Position of the player on the previous surface.
-- * previousSurface: LuaSurface on which the player was before opening this GUI.
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
        object.previousPosition = {0,0}
        object.playerGui = PlayerGui.new{
            player = object,
        }
        object.appController = AppController.new{
            appResources = AppResources.new{
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
        PlayerGui.setmetatable(object.playerGui)
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

        -- Shows the current app, and moves the player to the drawing surface.
        --
        -- Args:
        -- * self: Player object.
        --
        show = function(self)
            if not self.opened then
                self.opened = true
                local targetPosition = self.previousPosition
                self.previousControllerType = self.rawPlayer.controller_type
                if self.previousControllerType == defines.controllers.character then
                    self.previousCharacter = self.rawPlayer.character
                end
                self.previousPosition = self.rawPlayer.position
                self.previousSurface = self.rawPlayer.surface
                self.rawPlayer.set_controller{type = defines.controllers.god}
                self.rawPlayer.teleport(targetPosition, self.graphSurface)
                self.appController.app:show()
            end
        end,

        -- Hides the current app, and moves the player back to the last known surface.
        --
        -- Args:
        -- * self: Player object.
        --
        hide = function(self)
            if self.opened then
                self.opened = false
                local targetPosition = self.previousPosition
                self.previousPosition = self.rawPlayer.position
                self.rawPlayer.teleport(targetPosition, self.previousSurface)
                local newController = {
                    type = self.previousControllerType,
                }
                if newController.type == defines.controllers.character then
                    if self.previousCharacter.valid then
                        newController.character = self.previousCharacter
                    else
                        newController.type = defines.controllers.ghost
                    end
                end
                self.rawPlayer.set_controller(newController)
                self.appController.app:hide()
            end
        end,

        -- Switches the "opened" state of this player GUI.
        --
        -- Args:
        -- * self: Player object.
        --
        toggleOpened = function(self)
            if self.opened then
                self:hide()
            else
                self:show()
            end
        end,
    },
}

return Player
