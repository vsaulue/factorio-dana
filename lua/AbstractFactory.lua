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
local getClassOfObject
local assertClassField

-- Utility class to create virtual objects and/or restore their metatables.
--
-- Classes usable by this factory are tables with the following fields:
-- * setmetatable: restore the metatable of the object, and all its owned objects.
-- * new: creates a new object (optional: required only if enableMake is set).
--
-- RO Fields:
-- * classes[name]: Map of class tables, indexed by their names.
-- * enableMake: boolean to enable the make() method.
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
        object.enableMake = object.enableMake or false
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the AbstractFactory class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Creates a new instance of one of the wrapped type.
        --
        -- The exact type & constructor is determined with getClassNameOfObject.
        --
        -- Args:
        -- * self: AbstractFactory object.
        -- * object: Constructor argument.
        --
        -- Returns: The new object constructed from the argument.
        --
        make = function(self, object)
            cLogger:assert(self.enableMake, "make() can't be used with 'enableMake == false'")
            return getClassOfObject(self, object).new(object)
        end,

        -- Registers a new class for this factory.
        --
        -- Args:
        -- * self: AbstractFactory object.
        -- * className: Name of the class to register.
        -- * classTable: Table of the class (= the table containing the appropriate setmetatable function).
        --
        registerClass = function(self, className, classTable)
            cLogger:assert(not rawget(self.classes, className), "Duplicate class name: " .. className)
            if self.enableMake then
                assertClassField(classTable, "new")
            end
            assertClassField(classTable, "setmetatable")
            self.classes[className] = classTable
        end,

        -- Restores the metatable of an object.
        --
        -- Args:
        -- * self: AbstractFactory object.
        -- * object: table to modify.
        --
        restoreMetatable = function(self, object)
            getClassOfObject(self, object).setmetatable(object)
        end,
    },
}

-- Asserts that a field is defined in the given class table.
--
-- Args:
-- * classTable: Class table to check.
-- * fieldName: Key of the field to check.
--
assertClassField = function(classTable, fieldName)
    if not classTable[fieldName] then
        cLogger:error("Invalid class table (missing '" .. fieldName .. "' function).")
    end
end

-- Gets the class table of a given object.
--
-- The object does not necessarily have a metatable set at this point.
--
-- Args:
-- * self: AbstractFactory object.
-- * object: An object of any type managed by this factory.
--
-- Returns: The class table of the object.
--
getClassOfObject = function(self, object)
    local className = self.getClassNameOfObject(object)
    cLogger:assert(className, "Unable to retrieve the class name of the object.")
    return self.classes[className]
end

return AbstractFactory
