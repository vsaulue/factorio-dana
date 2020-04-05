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

-- Utility module to run binary searches on sorted Array & ReversibleArray objects.
--
-- All these functions assumes that the array is sorted. Undefined behaviour otherwise.
--
local ArrayBinarySearch = ErrorOnInvalidRead.new{
    findIndexesAround = nil,

    findIndexesInRange = nil,
}

-- Map of comparisons functions for findIndexesAround.
local ComparisonFunctions = ErrorOnInvalidRead.new{
    -- Comparison function to use to have a strict upper bound.
    [true] = function(a,b)
        return a < b
    end,

    -- Comparison function to use to have a "greater or equal" upper bound.
    [false] = function(a,b)
        return a <= b
    end,
}

-- Gets the indices of the "closest" values in an array.
--
-- This function looks for an index `i` (unique, if it exists) in the array such as:
-- * if isUpperBoundStrict: array[i] <= value <  array[i+1]
-- * else:                  array[i] <  value <= array[i+1]
--
-- If no such value exist, it either means that:
-- * value <= array[1] : the function returns 0
-- * array[array.count] <= value: the function returns `array.count`.
--
-- Args:
-- * array: Array on which the binary search will be run.
-- * value: Value to look for.
-- * isUpperBoundStrict: Parameter to handle the equality cases.
--
-- Returns: The unique index as described above.
--
function ArrayBinarySearch.findIndexesAround(array, value, isUpperBoundStrict)
    local lowerThan = ComparisonFunctions[isUpperBoundStrict]
    local lowId = 1
    local lowValue = array[1]
    local highId = array.count
    local highValue = array[highId]
    if lowerThan(value, lowValue) then
        lowId = 0
        highId = 1
    elseif not lowerThan(value, highValue) then
        lowId = highId
        highId = highId + 1
    else
        while highId - lowId > 1 do
            local middleId = math.floor((highId + lowId) / 2)
            local middleValue = array[middleId]
            if lowerThan(value, middleValue) then
                highId = middleId
                highValue = middleValue
            else
                lowId = middleId
                lowValue = middleValue
            end
        end
        assert(not lowerThan(value, array[lowId]))
        assert(lowerThan(value, array[highId]))
    end
    return lowId
end

-- Gets the sequence of values in an array contained in a specified interval.
--
-- Args:
-- * array: Array on which the binary search will be run.
-- * lowerBound: Lower bound of the interval to look for.
-- * upperBound: Upper bound of the interval to look for.
-- * isLowerBoundStrict: True only if values equal to lowerBound should be included in the result.
-- * isUpperBoundStrict: True only if values equal to upperBound should be included in the result.
--
-- Returns:
-- * The first index `i` in the array such as: lowerBound <= array[i] (strict inequality if isLowerBoundStrict)
-- * The first index `j` in the array such as: array[j] <= upperBound (strict inequality if isUpperBoundStrict)
--
function ArrayBinarySearch.findIndexesInRange(array, lowerBound, upperBound, isLowerBoundStrict, isUpperBoundStrict)
    local findIndexesAround = ArrayBinarySearch.findIndexesAround
    local lowId = 1 + findIndexesAround(array, lowerBound, isLowerBoundStrict)
    local highId = findIndexesAround(array, upperBound, not isUpperBoundStrict)
    return lowId,highId
end

return ArrayBinarySearch
