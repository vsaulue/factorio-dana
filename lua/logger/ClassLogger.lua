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

local Logger = require("lua/logger/Logger")

local Metatable

-- Class for logging informations related to a specific class.
--
-- RO fields:
-- * className: Name of the class logged by this object.
--
local ClassLogger = {
    -- Creates a new ClassLogger object.
    --
    -- Args:
    -- * object: Table to turn into a ClassLogger object (must have the 'className' field).
    --
    -- Returns: The argument turned into a ClassLogger object.
    --
    new = function(object)
        assert(object.className, "ClassLogger: missing mandatory 'className' field.")
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the ClassLogger class.
Metatable = {
    __index = {
        -- Logs an error message and terminate the program if a condition is not met.
        --
        -- Args:
        -- * self: ClassLogger object.
        -- * condition: Condition to check before logging an error and exiting.
        -- * message: Message to log.
        --
        assert = function(self, condition, message)
            if not condition then
                Logger.error(self.className .. ": " .. message)
            end
        end,

        -- Asserts that a field is properly set in an object.
        --
        -- Logs an error message & terminate if the field is not set.
        --
        -- Args:
        -- * self: ClassLogger object.
        -- * object: Object whose field must be checked.
        -- * fieldName: Key of the field to check.
        --
        -- Returns: The value of the field.
        --
        assertField = function(self, object, fieldName)
            local result = object[fieldName]
            if result == nil then
                Logger.error(self.className .. ": missing mandatory '" .. fieldName .. "' field.")
            end
            return result
        end,

        -- Asserts that a field is properly set in an object.
        --
        -- Logs an error message & terminate if the field is not set.
        --
        -- Args:
        -- * self: ClassLogger.
        -- * object: table. Object whose field must be checked.
        -- * index: any. Key of the field to check.
        -- * typeName: string. Expected type.
        --
        -- Returns: The value of the field.
        --
        assertFieldType = function(self, object, index, typeName)
            local result = self:assertField(object, index)
            if type(result) ~= typeName then
                Logger.error(self.className .. ": invalid type for field '" .. tostring(index) .. "' (" .. typeName .. " expected).")
            end
            return result
        end,

        -- Logs an error message & and terminates the program.
        --
        -- Args:
        -- * self: ClassLogger object
        -- * message: Message to log.
        --
        error = function(self, message)
            Logger.error(self.className .. ": " .. message)
        end,

        -- Logs a warning message.
        --
        -- Args:
        -- * self: ClassLogger object.
        -- * message: Message to log.
        --
        warn = function(self, message)
            Logger.warn(self.className .. ": " .. message)
        end,
    }
}

return ClassLogger
