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
local Logger = require("lua/logger/Logger")

-- Class implementing an ordered set.
--
-- Optimized for fast insertion/deletion of elements (constant time if the predecessor is known).
--
-- RO properties:
-- * backward[next]: map giving the previous element in the set.
-- * forward[prev]: map giving the next element in the set.
--
-- Constants:
-- * Begin: Sentinel value, placed before the first element of an ordered set.
-- * End: Sentinel value, placed after the last element of an ordered set.
--
-- Methods:
-- * insertAfter: inserts the given element at the specified position.
-- * pushBack: Inserts a new value at the end of the set.
-- * pushFront: Inserts a new value at the beginning of the set.
-- * removeAfter: deletes the element at the given position.
--
local OrderedSet = ErrorOnInvalidRead.new{
    new = nil, -- implemented later

    newFromArray = nil, -- implemented later

    -- Sentinel value, placed before the first element of an ordered set.
    Begin = {},

    -- Sentinel value, placed after the last element of an ordered set.
    End = {},
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    -- Metatable of the OrderedSet class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Inserts a new value at the given position.
            --
            -- Args:
            -- * self: OrderedSet object.
            -- * previous: A value already in the list. newValue will be inserted after it.
            -- * newValue: The new value to add.
            --
            insertAfter = function(self, previous, newValue)
                local backward = self.backward
                local forward = self.forward
                assert(not rawget(forward, newValue), "OrderedSet: Duplicate value: " .. tostring(newValue))
                local next = forward[previous]
                forward[previous] = newValue
                forward[newValue] = next
                backward[next] = newValue
                backward[newValue] = previous
            end,

            -- Inserts a new value at the end of the set.
            --
            -- Args:
            -- * self: OrderedSet object.
            -- * value: The new value to add.
            --
            pushBack = function(self, newValue)
                self:insertAfter(self.backward[OrderedSet.End], newValue)
            end,

            -- Inserts a new value at the beginning of the set.
            --
            -- Args:
            -- * self: OrderedSet object.
            -- * newValue: The new value to add.
            --
            pushFront = function(self, newValue)
                self:insertAfter(OrderedSet.Begin, newValue)
            end,

            -- Removes a given value.
            --
            -- Args:
            -- * self: OrderedSet object.
            -- * value: The value to remove.
            --
            remove = function(self, value)
                local backward = self.backward
                local forward = self.forward
                local previous = backward[value]
                local next = forward[value]
                forward[previous] = next
                backward[next] = previous
                forward[value] = nil
                backward[value] = nil
            end,

            -- Proxy to constant.
            Begin = OrderedSet.Begin,

            -- Proxy to constant.
            End = OrderedSet.End,
        },
    },
}

-- Creates a new OrderedSet object.
--
-- Returns: the new OrderedSet object.
--
function OrderedSet.new()
    local Begin = OrderedSet.Begin
    local End = OrderedSet.End
    local result = {
        backward = ErrorOnInvalidRead.new{
            [End] = Begin,
        },
        forward = ErrorOnInvalidRead.new{
            [Begin] = End,
        },
    }
    setmetatable(result, Impl.Metatable)
    return result
end

-- Creates a new OrderedSet object, from the values stored in an Array object.
--
-- Args:
-- * array: Array (or ReversibleArray) object containing the initial values.
--
-- Returns: the new OrderedSet object.
--
function OrderedSet.newFromArray(array)
    local result = OrderedSet.new()
    local pushFront = result.pushFront
    local Begin = OrderedSet.Begin
    for i=array.count,1,-1 do
        pushFront(result, array[i])
    end
    return result
end

return OrderedSet
