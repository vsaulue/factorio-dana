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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "AppResources"}

-- Object holding shared resources for all the applications owned by the same player.
--
-- RO Field:
-- * force: Force object, corresponding to the force this player belongs to.
-- * rawPlayer: LuaPlayer object from Factorio.
-- * surface: LuaSurface that this application can use to draw.
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
        cLogger:assertField(object, "rawPlayer")
        cLogger:assertField(object, "surface")
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of a GraphApp object, and all its owned objects.
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

return AppResources
