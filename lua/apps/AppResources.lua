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

local AppUpcalls = require("lua/apps/AppUpcalls")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local PositionController = require("lua/apps/PositionController")

local cLogger = ClassLogger.new{className = "AppResources"}

local Metatable

-- Object holding shared resources for all the applications owned by the same player.
--
-- RO Field:
-- * force: Force object, corresponding to the force this player belongs to.
-- * menuFlow: GUI Flow usable by this application in the top menu.
-- * positionController: PositionController object.
-- * rawPlayer: LuaPlayer object from Factorio.
-- * surface: LuaSurface that this application can use to draw.
-- * upcalls: AppUpcalls. List of callbacks to the upper controller.
--
local AppResources = ErrorOnInvalidRead.new{
    -- Creates a new AppResources object.
    --
    -- Args:
    -- * object: Table to turn into an AppResources object (required fields: all).
    --
    -- Returns: The argument turned into an AppResources object.
    new = function(object)
        cLogger:assertField(object, "force")
        cLogger:assertField(object, "menuFlow")
        local rawPlayer = cLogger:assertField(object, "rawPlayer")
        local surface = cLogger:assertField(object, "surface")
        cLogger:assertField(object, "upcalls")

        object.positionController = PositionController.new{
            appSurface = surface,
            rawPlayer = rawPlayer,
        }

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of an AppResources object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        PositionController.setmetatable(object.positionController)
    end,
}

-- Metatable of the AppResources class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AppUpcalls:makeAndSwitchApp().
        makeAndSwitchApp = function(self, newApp)
            self.upcalls:makeAndSwitchApp(newApp)
        end,

        -- Implements AppUpcalls:setPosition().
        setPosition = function(self, position)
            self.upcalls:setPosition(position)
        end,
    },
}
AppUpcalls.check(Metatable.__index)

return AppResources
