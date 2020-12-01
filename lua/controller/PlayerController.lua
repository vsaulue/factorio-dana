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
local MenuWindow = require("lua/controller/MenuWindow")
local ModGui = require("mod-gui")
local ModGuiButton = require("lua/controller/ModGuiButton")
local PlayerCtrlInterface = require("lua/controller/PlayerCtrlInterface")
local PositionController = require("lua/controller/PositionController")

local closeApp
local Metatable
local setApp
local setDefaultApp
local ShortcutName
local updateModGuiButton

-- Class holding data associated to a player in this mod.
--
-- Implements AppUpcalls, GuiUpcalls, PlayerCtrlInterface.
--
-- Fields:
-- * app: AbstractApp or false. Running application.
-- * appResources: AppResources. Resources used by this player's applications.
-- * force: Force this player belongs to.
-- * modGuiButton: ModGuiButton. Button in the mod-gui flow.
-- * rawPlayer: Associated LuaPlayer instance.
-- * graphSurface: LuaSurface used to display graphs to this player.
-- * menuWindow: MenuWindow. Top-left menu window of this player.
-- * positionController: PositionController.
--
-- RO properties:
-- * opened: true if the GUI is opened.
--
local PlayerController = ErrorOnInvalidRead.new{
    -- Creates a new PlayerController object.
    --
    -- Args:
    -- * object: table to turn into the PlayerController object (required fields: force, graphSurface, rawPlayer).
    --
    new = function(object)
        setmetatable(object, Metatable)
        object.opened = false
        -- Open button
        object.modGuiButton = ModGuiButton.new{
            playerCtrlInterface = object,
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
        updateModGuiButton(object)
        return object
    end,

    -- Restores the metatable of a PlayerController instance, and all its owned objects.
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
        ModGuiButton.setmetatable(object.modGuiButton)
    end,
}

-- Metatable of the PlayerController class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AppUpcalls:makeAndSwitchApp().
        makeAndSwitchApp = function(self, newApp)
            closeApp(self)
            newApp.appResources = self.appResources
            setApp(self, App.new(newApp))
        end,

        -- Implements GuiUpcalls:notifyGuiCorrupted().
        --
        -- Repair all GUIs of this player.
        --
        notifyGuiCorrupted = function(self)
            self.rawPlayer.print{"dana.player.guiCorruptedMessage"}
            self.menuWindow:repair(self.rawPlayer.gui.screen)
            self.modGuiButton:repair(ModGui.get_button_flow(self.rawPlayer))
            if self.app then
                self.app:repairGui()
            end
        end,

        -- Function to call when Factorio's on_player_changed_surface is triggered for this player.
        --
        -- Args:
        -- * self: PlayerController object.
        -- * event: Factorio event.
        --
        onChangedSurface = function(self, event)
            if event.surface_index == self.graphSurface.index and self.opened then
                self:hide(true)
            end
        end,

        -- Function to call when Factorio's on_lua_shortcut is triggered for this player.
        --
        -- Args:
        -- * self: PlayerController.
        -- * event: table. Factorio event.
        --
        onLuaShortcut = function(self, event)
            if event.prototype_name == ShortcutName then
                if self.opened then
                    self:hide(false)
                else
                    self:show()
                end
            end
        end,

        -- Function to call when Factorio's on_player_selected_area is triggered for this player.
        --
        -- Args:
        -- * self: PlayerController object.
        -- * event: Factorio event.
        --
        onSelectedArea = function(self, event)
            self.app:onSelectedArea(event)
        end,

        -- Function to call when a "runtime-per-user" mod setting is changes.
        --
        -- Args:
        -- * self: PlayerController.
        -- * event: table. Factorio's event from on_runtime_mod_setting_changed.
        --
        onUserModSettingChanged = function(self, event)
            if event.setting == "dana-enable-top-left-button" then
                updateModGuiButton(self)
            end
        end,

        -- Implements AppUpcalls:setAppMenu().
        setAppMenu = function(self, appMenu)
            self.menuWindow:setAppMenu(appMenu)
        end,

        -- Implements AppUpcalls:setPosition().
        setPosition = function(self, position)
            self.positionController:setPosition(position)
        end,

        -- Implements PlayerCtrlInterface:show().
        show = function(self)
            if self.app and not self.opened then
                self.opened = true
                self.rawPlayer.opened = nil
                self.rawPlayer.set_shortcut_toggled(ShortcutName, true)
                self.menuWindow:open(self.rawPlayer.gui.screen)
                self.positionController:teleportToApp()
                self.app:show()
                self.rawPlayer.opened = self.menuWindow.gui.frame
            end
        end,

        -- Hides Dana's GUI, and moves the player back to its last position/surface.
        --
        -- Args:
        -- * self: PlayerController object.
        -- * keepPosition: false to teleport the player at the the position he had while opening Dana.
        --   true to stay at the current position.
        --
        hide = function(self, keepPosition)
            if self.opened then
                self.opened = false
                self.rawPlayer.set_shortcut_toggled(ShortcutName, false)
                self.menuWindow:close()
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
        -- * self: PlayerController object.
        --
        reset = function(self)
            closeApp(self)
            self:hide(false)
            setDefaultApp(self)
        end,
    },
}
AppUpcalls.check(Metatable.__index)
PlayerCtrlInterface.check(Metatable.__index)

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

-- Name of Dana's open/close shortcut.
ShortcutName = "dana-shortcut"

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

-- Updates the modGuiButton's status according to the mod settings.
--
-- Args:
-- * self: PlayerController.
--
updateModGuiButton = function(self)
    local oldValue = rawget(self.modGuiButton, "gui")
    local newValue = self.rawPlayer.mod_settings["dana-enable-top-left-button"].value
    if newValue ~= oldValue then
        if newValue then
            self.modGuiButton:open(ModGui.get_button_flow(self.rawPlayer))
        else
            self.modGuiButton:close()
        end
    end
end

return PlayerController
