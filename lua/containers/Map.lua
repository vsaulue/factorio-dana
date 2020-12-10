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
local Set = require("lua/containers/Set")

local cLogger = ClassLogger.new{className = "Map"}

local defaultCopy
local defaultValueEquals

-- Pseudo-class representing a map.
--
-- Any table used as a generic key/value store is considered a map.
--
local Map = ErrorOnInvalidRead.new{
    -- Creates a copy of a map.
    --
    -- Args:
    -- * map: table. Object to copy.
    -- * keyCopy (optional): function(any) -> any. Function to build a copy of key entries.
    -- * valueCopy (optional): function(any) -> any. Function to build a copy of value entries.
    --
    -- Returns: table. A copy of `map`.
    --
    copy = function(map, keyCopy, valueCopy)
        keyCopy = keyCopy or defaultCopy
        valueCopy = valueCopy or defaultCopy
        local result = {}
        for k,v in pairs(map) do
            local newKey = keyCopy(k)
            cLogger:assert(result[newKey] == nil, "copy(): Duplicate key from keyCopy function.")
            result[newKey] = valueCopy(v)
        end
        return result
    end,

    -- Tests if two maps are equals.
    --
    -- Args:
    -- * map1: table.
    -- * map2: table.
    -- * valueEquals (optional): function(any,any) -> boolean. Function used to compare the values.
    --
    -- Returns: boolean. True for equality, false otherwise.
    --
    equals = function(map1, map2, valueEquals)
        valueEquals = valueEquals or defaultValueEquals
        local count = 0
        for k1,v1 in pairs(map1) do
            local v2 = rawget(map2, k1)
            if (not v2) or not valueEquals(v1, v2) then
                return false
            end
            count = count + 1
        end
        return Set.checkCount(map2, count)
    end,
}

-- Default copy function for keys & values: identity.
--
-- Args:
-- * value: any. Value to copy.
--
-- Returns: any.
--
defaultCopy = function(value)
    return value
end

-- Default compare function for values: identity.
--
-- Args:
-- * v1: any.
-- * v2: any.
--
-- Returns: boolean. True for equality, false otherwise.
--
defaultValueEquals = function(v1,v2)
    return v1 == v2
end

return Map
