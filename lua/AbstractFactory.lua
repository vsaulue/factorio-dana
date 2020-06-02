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

local cLogger = ClassLogger.new{className = "AbstractFactory"}

local Metatable

-- Utility class to restore metatables of virtual/abstract types.
--
-- RO Fields:
-- * classes[name]: Map of class tables, indexed by their names.
-- * getClassNameOfObject (abstract): Function (NOT method) to get the class name of an object.
--       Note that at this point, the object doesn't have a metatable (this function can't be implemented with
--       any __index field of the argument).
--
-- Methods: see Metatable.__index
--
local AbstractFactory = ErrorOnInvalidRead.new{
    -- Creates a new AbstractFactory object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractFactory object (required field: getClassNameOfObject).
    --
    -- Returns: The argument turned into an AbstractFactory object.
    --
    new = function(object)
        cLogger:assertField(object, "getClassNameOfObject")
        object.classes = ErrorOnInvalidRead.new()
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the AbstractFactory class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Registers a new class for this factory.
        --
        -- Args:
        -- * self: AbstractFactory object.
        -- * className: Name of the class to register.
        -- * classTable: Table of the class (= the table containing the appropriate setmetatable function).
        --
        registerClass = function(self, className, classTable)
            cLogger:assert(not rawget(self.classes, className), "Duplicate class name: " .. className)
            cLogger:assert(classTable.setmetatable, "Invalid class table (missing 'setmetatable' function).")
            self.classes[className] = classTable
        end,

        -- Restores the metatable of an object.
        --
        -- Args:
        -- * self: AbstractFactory object.
        -- * object: table to modify.
        --
        restoreMetatable = function(self, object)
            local className = self.getClassNameOfObject(object)
            cLogger:assert(className, "Unable to retrieve the class name of the object.")
            self.classes[className].setmetatable(object)
        end,
    },
}

return AbstractFactory
