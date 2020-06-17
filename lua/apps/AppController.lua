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
local QueryApp = require("lua/apps/query/QueryApp")

local cLogger = ClassLogger.new{className = "AppController"}

local Metatable

-- Class booting & switching applications for a Player.
--
-- RO Fields:
-- * app: AbstractApp currently running.
-- * appResources: AppResources object used by the current application.
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
        setmetatable(object, Metatable)

        object.app = QueryApp.new{
            appController = object,
        }
        object.app:hide()

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
        -- Creates a new application, and runs it in place of the current one.
        --
        -- Args:
        -- * self: AppController object.
        -- * newApp: table used to build the new application.
        --
        makeAndSwitchApp = function(self, newApp)
            self.app:close()
            newApp.appController = self
            self.app = AbstractApp.Factory:make(newApp)
            self.app:show()
        end,
    }
}

return AppController
