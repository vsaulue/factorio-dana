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

-- Container implementing a reversible array.
--
-- A ReversibleArray is an ordered set, which can easily be accessed both way:
-- * given an index N, get the N-th value of the set.
-- * given a value, get the index of this value.
--
-- Currently values can't be of String or Int/Float type.s
--
-- RO fields:
-- * count: The number of values stored.
-- * (int): the value of the N-th
-- * (other): the index of this value.
--
-- Methods:
-- * getLowHighValues: Returns the two input values, reordered to match their indices' order.
-- * popBack: Removes and returns the last value of this ReversibleArray.
-- * pushBack: Adds a new value at the end of this ReversibleArray.
-- * pushBackIfNotPresent: Append a value if it's not already present, else does nothing.
-- * sort: sorts the array in place.
--
local ReversibleArray = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
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
    end,

    -- Metatable of the LayerLink class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Returns the two input values, reordered to match their indices' order.
            --
            -- Args:
            -- * self: Couplings object.
            -- * valueA: Some value.
            -- * valueB: Another value.
            --
            -- Returns:
            -- * The value with the lower index.
            -- * The value with the greater index.
            --
            getLowHighValues = function(self, valueA, valueB)
                local idA = self[valueA]
                local idB = self[valueB]
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
                assert(count > 0, "ReversibleArray: attempt to popBack() an empty array.")
                local result = self[count]
                self[count] = nil
                self[result] = nil
                self.count = count - 1
                return result
            end,

            -- Adds a new value at the end of this ReversibleArray.
            --
            -- Args:
            -- * self: ReversibleArrayobject.
            -- * value: The new value to add.
            --
            pushBack = function(self, value)
                local valueType = type(x)
                assert(value, "ReversibleArray: nil value is not supported.")
                assert(valueType ~= "number", "ReversibleArray: number values are not supported.")
                assert(valueType ~= "string", "ReversibleArray: string values are not supported.")
                assert(not rawget(self, value), "ReversibleArray: duplicate values.")

                local count = self.count + 1
                self.count = count
                self[count] = value
                self[value] = count
            end,

            -- Append a value if it's not already present, else does nothing.
            --
            -- Args:
            -- * self: ReversibleArrayobject.
            -- * value: The value to append, if it's not already present.
            --
            pushBackIfNotPresent = function(self, value)
                if not rawget(self, value) then
                    self:pushBack(value)
                end
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
                    self[value] = i
                end
            end,
        },
    },
}

function Impl.Metatable.__ipairs(self)
    return Impl.iteratorNext, self, 0
end

Impl.Metatable.__pairs = Impl.Metatable.__ipairs

-- Creates a new empty ReversibleArray.
--
-- Returns: The new ReversibleArray object.
--
function ReversibleArray.new()
    local result = {
        count = 0,
    }
    setmetatable(result, Impl.Metatable)
    return result
end

return ReversibleArray
