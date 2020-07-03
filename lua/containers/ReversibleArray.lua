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

local cLogger = ClassLogger.new{className = "ReversibleArray"}

local Metatable
local iteratorNext

-- Container implementing a reversible array.
--
-- A ReversibleArray is an ordered set, which can easily be accessed both way:
-- * given an index N, get the N-th value of the set.
-- * given a value, get the index of this value.
--
-- RO fields:
-- * count: The number of values stored.
-- * reverse[value]: Map giving the index of a given value.
-- * (int): the value of the N-th element.
--
local ReversibleArray = ErrorOnInvalidRead.new{
    -- Creates a new empty ReversibleArray.
    --
    -- Returns: The new ReversibleArray object.
    --
    new = function()
        local result = {
            count = 0,
            reverse = ErrorOnInvalidRead.new(),
        }
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a ReversibleArray object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        ErrorOnInvalidRead.setmetatable(object.reverse)
    end,
}

-- Metatable of the ReversibleArray class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Returns the two input values, reordered to match their indices' order.
        --
        -- Args:
        -- * self: ReversibleArray object.
        -- * valueA: Some value.
        -- * valueB: Another value.
        --
        -- Returns:
        -- * The value with the lower index.
        -- * The value with the greater index.
        --
        getLowHighValues = function(self, valueA, valueB)
            local idA = self.reverse[valueA]
            local idB = self.reverse[valueB]
            local lowValue = valueB
            local highValue = valueA
            if idA < idB then
                lowValue = valueA
                highValue = valueB
            end
            return lowValue, highValue
        end,

        -- Removes and returns the last value of this ReversibleArray.
        --
        -- Args:
        -- * self: ReversibleArray object.
        --
        -- Returns: The value removed at the end of this array.
        --
        popBack = function(self)
            local count = self.count
            cLogger:assert(count > 0, "attempt to popBack() an empty array.")
            local result = self[count]
            self[count] = nil
            self.reverse[result] = nil
            self.count = count - 1
            return result
        end,

        -- Adds a new value at the end of this ReversibleArray.
        --
        -- Args:
        -- * self: ReversibleArray object.
        -- * value: The new value to add.
        --
        pushBack = function(self, value)
            cLogger:assert(value, "nil value is not supported.")
            cLogger:assert(not rawget(self.reverse, value), "duplicate values.")

            local count = self.count + 1
            self.count = count
            self[count] = value
            self.reverse[value] = count
        end,

        -- Append a value if it's not already present, else does nothing.
        --
        -- Args:
        -- * self: ReversibleArrayobject.
        -- * value: The value to append, if it's not already present.
        --
        pushBackIfNotPresent = function(self, value)
            if not rawget(self.reverse, value) then
                self:pushBack(value)
            end
        end,

        -- Removes a given index/value pair by value.
        --
        -- Args:
        -- * self: ReversibleArray object.
        -- * removedValue: Value to remove.
        --
        -- Returns: The index of the removed value.
        --
        removeValue = function(self, removedValue)
            local removedIndex = self.reverse[removedValue]
            table.remove(self, removedIndex)
            self.count = self.count - 1
            for index=removedIndex,self.count do
                local value = self[index]
                self.reverse[value] = index
            end
            self.reverse[removedValue] = nil
            return removedIndex
        end,

        -- Sorts this reversible array in place.
        --
        -- Args:
        -- * self: ReversibleArray object to sort.
        -- * weights[arrayValue]: a map giving a score for each value in the array. Values will be sorted
        -- from lowest to greatest scores.
        --
        sort = function(self, weights)
            local compare = function(a,b)
                local w = weights
                return w[a] < w[b]
            end
            table.sort(self, compare)
            for i=1,self.count do
                local value = self[i]
                self.reverse[value] = i
            end
        end,
    },

    __ipairs = function(self)
        return iteratorNext, self, 0
    end,
}
Metatable.__pairs = Metatable.__ipairs

-- Function used to iterate through a ReversibleArray object.
--
-- Args:
-- * self: ReversibleArray object.
-- * index: Index of the element accessed in the previous iteration step.
--
-- Returns:
-- * The index of the next element (or nil if the end of the array was reached).
-- * The value of the next element (or nil if the end of the array was reached).
--
iteratorNext = function(self, index)
    local nextIndex = index + 1
    local nextValue = nil
    if nextIndex <= self.count then
        nextValue = self[nextIndex]
    else
        nextIndex = nil
    end
    return nextIndex, nextValue
end

return ReversibleArray
