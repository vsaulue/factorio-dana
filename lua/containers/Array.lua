-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local Logger = require("lua/Logger")

-- Container class with array semantics.
--
-- This class caches the length of the array, and errors when reading an nil value.
--
-- Fields:
-- * count: Number of element & index of the last element. Writing it can shrink/expand the array. After an expand,
-- new values are not initialized (not necessarily nil -> "undefined behaviour" on read).
-- * [n]: n-th value in this array. "undefined behaviour" if out of bounds.
--
-- Methods:
-- * loadFromOrderedSet: Replaces the content of this array with the values stored in an OrderedSet object.
-- * pushBack: adds a new value at the end of the array.
-- * pushBackIteratorAll: Push back all remaining values from an iterator.
-- * pushBackIteratorOnce: Push back the current value of an iterator, and call next() once.
-- * sort: sorts the array in place.
--
local Array = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

local Impl = ErrorOnInvalidRead.new{
    -- Function used to iterate through an Array object.
    --
    -- Args:
    -- * self: Array object.
    -- * index: Index of the element accessed in the previous iteration step.
    --
    -- Returns:
    -- * The index of the next element (or nil if the end of the array was reached).
    -- * The value of the next element (or nil if the end of the array was reached).
    --
    iteratorNext = function(self,index)
        local nextIndex = index + 1
        local nextValue = nil
        if nextIndex <= self.count then
            nextValue = self[nextIndex]
        else
            nextIndex = nil
        end
        return nextIndex, nextValue
    end,

    -- Metatable of the array class.
    Metatable = {
        __eq = function(self, otherTable)
            local result = rawequal(self, otherTable)
            if not result then
                local sCount = self.count
                result = sCount == otherTable.count
                local i = 1
                while i <= sCount and result do
                    result = self[i] == otherTable[i]
                    i = i + 1
                end
            end
            return result
        end,

        __index = ErrorOnInvalidRead.new{
            -- Replaces the content of this array with the values stored in an OrderedSet object.
            --
            -- Args:
            -- * self: Array object.
            -- * orderedSet: OrderedSet containing the values to import.
            --
            loadFromOrderedSet = function(self, orderedSet)
                local End = orderedSet.End
                local forward = orderedSet.forward
                local it = forward[orderedSet.Begin]
                local count = 0
                while it ~= End do
                    count = count + 1
                    self[count] = it
                    it = forward[it]
                end
                self.count = count
            end,

            -- Adds a new value at the end of the array.
            --
            -- Args:
            -- * self: Array object.
            -- * value: Value to add at the end of the array.
            --
            pushBack = function(self, value)
                local count = self.count + 1
                self[count] = value
                self.count = count
            end,

            -- Push back all remaining values from an iterator.
            --
            -- Args:
            -- * self: Array object.
            -- * iterator: Iterator holding the values to push.
            --
            pushBackIteratorAll = function(self, iterator)
                local value = iterator.value
                while value do
                    self:pushBack(value)
                    iterator:next()
                    value = iterator.value
                end
            end,

            -- Push back the current value of an iterator, and call next() once.
            --
            -- Args:
            -- * self: Array object.
            -- * iterator: Iterator holding the value to push back.
            --
            pushBackIteratorOnce = function(self, iterator)
                self:pushBack(iterator.value)
                iterator:next()
            end,

            -- Sorts this array in place.
            --
            -- Args:
            -- * self: Array object to sort.
            -- * weights[arrayValue]: a map giving a score for each value in the array. Values will be sorted
            -- from lowest to greatest scores.
            --
            sort = function(self, weights)
                local compare = function(a,b)
                    local w = weights
                    return w[a] < w[b]
                end
                table.sort(self, compare)
            end,
        },

        __ipairs = nil, -- implemented later

        __len = function(self)
            return self.count
        end,

        __pairs = nil, -- implemented later
    },
}

function Impl.Metatable.__ipairs(self)
    Logger.perfDebug("Array: __ipairs is deprecated. Use 'for i=1,array.count do ...' instead.")
    return Impl.iteratorNext, self, 0
end

function Impl.Metatable.__pairs(self)
    Logger.perfDebug("Array: __pairs is deprecated. Use 'for i=1,array.count do ...' instead.")
    return Impl.iteratorNext, self, 0
end

-- Creates a new Array object.
--
-- Args:
-- * object: Table to turn into an Array object (or nil to create an empty one).
--
-- Returns: a new empty array.
--
function Array.new(object)
    local result = object or {
        count = 0,
    }
    if object then
        result.count = result.count or #object
    end
    setmetatable(result, Impl.Metatable)
    return result
end

return Array
