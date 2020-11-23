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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local checkCount

-- Pseudo-class representing a genering set of objects.
--
-- Any table whose values are not "false" is considered a set.
--
local Set = ErrorOnInvalidRead.new{
    -- Tests if two sets are equals.
    --
    -- This is a "set" equality test, not a "map" test: only keys are checked.
    --
    -- Args:
    -- * set1: Set object.
    -- * set2: Another Set.
    --
    -- Returns: True if the sets contain the same elements.
    --
    areEquals = function(set1, set2)
        local result = true
        local count = 0
        for value in pairs(set1) do
            result = result and rawget(set2, value)
            count = count + 1
        end
        return (result and checkCount(set2, count)) or false
    end,

    -- Checks if a set has exactly the given amount of elements.
    --
    -- Args:
    -- * set: Set object.
    -- * expectedCount: Expected number of elements in `set`.
    --
    -- Returns: True if `set` has exactly `expectedCount` elements.
    --
    checkCount = function(set, expectedCount)
        local _next = next
        local value = nil
        repeat
            value = _next(set, value)
            expectedCount = expectedCount - 1
        until value == nil or expectedCount < -1
        return expectedCount == -1
    end,

    -- Checks if a set is a singleton of the specified element.
    --
    -- Args:
    -- * set: Set object.
    -- * element: Expected element in `set`.
    --
    -- Returns: True if `set` contains only `element`. False otherwise.
    --
    checkSingleton = function(set, value)
        local v1 = next(set)
        local v2 = next(set, v1)
        return (v1 == value) and (v2 == nil)
    end,

    -- Counts the number of elements in a set.
    --
    -- Args:
    -- * set: Set<any>.
    --
    -- Returns: int. The number of elements of the set.
    --
    count = function(set)
        local result = 0
        for _ in pairs(set) do
            result = result + 1
        end
        return result
    end,
}

checkCount = Set.checkCount

return Set
