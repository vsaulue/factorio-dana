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

local App = require("lua/apps/App")
local AppResources = require("lua/apps/AppResources")
local AppUpcalls = require("lua/apps/AppUpcalls")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local MenuWindow = require("lua/controller/MenuWindow")
local PositionController = require("lua/apps/PositionController")

local closeApp
local Metatable
local setApp
local setDefaultApp
local ShowButton

-- Class holding data associated to a player in this mod.
--
-- Stored in global: yes
--
-- Fields:
-- * app: AbstractApp or false. Running application.
-- * appResources: AppResources. Resources used by this player's applications.
-- * force: Force this player belongs to.
-- * rawPlayer: Associated LuaPlayer instance.
-- * graphSurface: LuaSurface used to display graphs to this player.
-- * menuWindow: MenuWindow. Top-left menu window of this player.
-- * positionController: PositionController.
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
        object.menuWindow = MenuWindow.new{
            playerCtrlInterface = object,
        }
        --
        object.positionController = PositionController.new{
            appSurface = object.graphSurface,
            rawPlayer = object.rawPlayer,
        }
        object.appResources = AppResources.new{
            force = object.force,
            rawPlayer = object.rawPlayer,
            surface = object.graphSurface,
            upcalls = object,
        }
        setDefaultApp(object)
        return object
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        if object.app then
            App.setmetatable(object.app)
        end
        AppResources.setmetatable(object.appResources)
        PositionController.setmetatable(object.positionController)
        MenuWindow.setmetatable(object.menuWindow)
        ShowButton.setmetatable(object.showButton)
    end,
}

-- Metatable of the Player class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AppUpcalls:makeAndSwitchApp().
        makeAndSwitchApp = function(self, newApp)
            closeApp(self)
            newApp.appResources = self.appResources
            setApp(self, App.new(newApp))
        end,

        -- Function to call when Factorio's on_player_changed_surface is triggered for this player.
        --
        -- Args:
        -- * self: Player object.
        -- * event: Factorio event.
        --
        onChangedSurface = function(self, event)
            if event.surface_index == self.graphSurface.index and self.opened then
                self:hide(true)
            end
        end,

        -- Function to call when Factorio's on_player_selected_area is triggered for this player.
        --
        -- Args:
        -- * self: Player object.
        -- * event: Factorio event.
        --
        onSelectedArea = function(self, event)
            self.app:onSelectedArea(event)
        end,

        -- Implements AppUpcalls:setAppMenu().
        setAppMenu = function(self, appMenu)
            self.menuWindow:setAppMenu(appMenu)
        end,

        -- Implements AppUpcalls:setPosition().
        setPosition = function(self, position)
            self.positionController:setPosition(position)
        end,

        -- Shows Dana's GUI, and moves the player to the drawing surface.
        --
        -- Args:
        -- * self: Player object.
        --
        show = function(self)
            if self.app and not self.opened then
                self.opened = true
                self.menuWindow:open(self.rawPlayer.gui.screen)
                self.showButton.rawElement.visible = false
                self.positionController:teleportToApp()
                self.app:show()
            end
        end,

        -- Hides Dana's GUI, and moves the player back to its last position/surface.
        --
        -- Args:
        -- * self: Player object.
        -- * keepPosition: false to teleport the player at the the position he had while opening Dana.
        --   true to stay at the current position.
        --
        hide = function(self, keepPosition)
            if self.opened then
                self.opened = false
                self.menuWindow:close()
                self.showButton.rawElement.visible = true
                if keepPosition then
                    self.positionController:restoreController()
                else
                    self.positionController:teleportBack()
                end
                if self.app then
                    self.app:hide()
                end
            end
        end,

        -- Leaves Dana mode, and switches to the default application.
        --
        -- Args:
        -- * self: Player object.
        --
        reset = function(self)
            closeApp(self)
            self:hide(false)
            setDefaultApp(self)
        end,
    },
}
AppUpcalls.check(Metatable.__index)

-- Closes the running application.
--
-- Args:
-- * self: AppController object.
--
closeApp = function(self)
    if self.app then
        self.app:close()
        self.menuWindow:setAppMenu(nil)
        self.app = false
    end
end

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

-- Sets a new application.
--
-- Args:
-- * self: AppController object.
-- * newApp: The new AbstractApp owned by this controller.
--
setApp = function(self, newApp)
    self.app = newApp
    if self.opened then
        self.app:show()
    else
        self.app:hide()
    end
end

-- Sets the default application.
--
-- Args:
-- * self: AppController object.
--
setDefaultApp = function(self)
    setApp(self, App.new{
        appName = "query",
        appResources = self.appResources,
    })
end

return Player
