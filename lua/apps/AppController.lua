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

local AbstractApp = require("lua/apps/AbstractApp")
local AppResources = require("lua/apps/AppResources")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")

-- Require all apps here, so that AbstractApp.Factory gets properly initialized.
local GraphApp = require("lua/apps/graph/GraphApp")
local QueryApp = require("lua/apps/query/QueryApp")

local cLogger = ClassLogger.new{className = "AppController"}

local closeApp
local Metatable
local setApp
local setDefaultApp

-- Class booting & switching applications for a Player.
--
-- RO Fields:
-- * app: AbstractApp currently running.
-- * appResources: AppResources object used by the current application.
-- * opened: Boolean indicating if the application is opened.
--
local AppController = ErrorOnInvalidRead.new{
    -- Creates a new AppController object.
    --
    -- Args:
    -- * object: Table to turn into an AppController object (required field: appResources).
    --
    -- Returns: The argument turned into an AppController object.
    --
    new = function(object)
        local appResources = cLogger:assertField(object, "appResources")
        object.opened = false
        setmetatable(object, Metatable)

        setDefaultApp(object)

        return object
    end,

    -- Restores the metatable of an AppController object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        AbstractApp.Factory:restoreMetatable(object.app)
        AppResources.setmetatable(object.appResources)
    end,
}

-- Metatable of the AppController class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Hides the current app, and moves the player back to the last known surface.
        --
        -- Args:
        -- * self: AppController object.
        --
        hide = function(self)
            cLogger:assert(self.opened, "invalid hide() call (GUI is already hidden).")
            self.opened = false
            self.appResources.positionController:teleportBack()
            self.app:hide()
        end,

        -- Creates a new application, and runs it in place of the current one.
        --
        -- Args:
        -- * self: AppController object.
        -- * newApp: table used to build the new application.
        --
        makeAndSwitchApp = function(self, newApp)
            closeApp(self)
            newApp.appController = self
            setApp(self, AbstractApp.Factory:make(newApp))
        end,

        -- Shows the current app, and moves the player to the drawing surface.
        --
        -- Args:
        -- * self: AppController object.
        --
        show = function(self)
            cLogger:assert(not self.opened, "invalid show() call (GUI is already visible).")
            self.opened = true
            self.appResources.positionController:teleportToApp()
            self.app:show()
        end,

        -- Replaces the current application with the default one.
        --
        -- Args:
        -- * self: AppController object.
        --
        switchToDefaultApp = function(self)
            closeApp(self)
            setDefaultApp(self)
        end
    }
}

-- Closes the running application.
--
-- Args:
-- * self: AppController object.
--
closeApp = function(self)
    self.app:close()
    GuiElement.clear(self.appResources.menuFlow)
    self.app = false
end

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
    setApp(self, QueryApp.new{
        appController = self
    })
end

return AppController
