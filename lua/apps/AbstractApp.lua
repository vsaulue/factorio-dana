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

local AbstractFactory = require("lua/AbstractFactory")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "AbstractApp"}

-- Class representing an application.
--
-- RO Fields:
-- * appName: String indicating the type of application.
--
local AbstractApp = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractApp objects.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.appName
        end,
    },

    -- Creates a new AbstractApp object.
    --
    -- Args:
    -- * object: Table to modify.
    -- * metatable: Metatable to set.
    --
    -- Returns: The argument turned into an AbstractApp object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "appName")
        setmetatable(object, metatable)
        return object
    end,
}

return AbstractApp
