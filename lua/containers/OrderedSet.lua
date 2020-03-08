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

-- Class implementing an ordered set.
--
-- Optimized for fast insertion/deletion of elements (constant time if the predecessor is known).
--
-- RO properties:
-- * entries[prev]: map giving the next element of the set.
--
-- Methods:
-- * insertAfter: inserts the given element at the specified position.
-- * pushFront: inserts a new value at the beginning of the set.
-- * removeAfter: deletes the element at the given position.
--
local OrderedSet = ErrorOnInvalidRead.new{
    new = nil, -- implemented later

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
            insertAfter = function(self,previous,newValue)
                local entries = self.entries
                assert(not rawget(entries, newValue), "OrderedSet: Duplicate value: " .. tostring(newValue))
                entries[newValue] = entries[previous]
                entries[previous] = newValue
            end,

            pushFront = nil, -- implemented later.

            -- Inserts a new value at the given position.
            --
            -- Args:
            -- * self: OrderedSet object.
            -- * previous: The value preceding the one to delete.
            --
            removeAfter = function(self,previous)
                local entries = self.entries
                local removedValue = entries[previous]
                entries[previous] = entries[removedValue]
                entries[removedValue] = nil
            end,
        },
    },
}

-- Inserts a new value at the beginning of the set.
--
-- Args:
-- * self: OrderedSet object.
-- * newValue: The new value to add.
--
function Impl.Metatable.__index.pushFront(self, newValue)
    local entries = self.entries
    assert(not rawget(entries, newValue), "OrderedSet: Duplicate value: " .. tostring(newValue))
    entries[newValue] = entries[OrderedSet.Begin]
    entries[OrderedSet.Begin] = newValue
end

-- Creates a new OrderedSet object.
--
-- Returns: the new OrderedSet object.
--
function OrderedSet.new()
    local result = {
        entries = ErrorOnInvalidRead.new{
            [OrderedSet.Begin] = OrderedSet.End,
        },
    }
    setmetatable(result, Impl.Metatable)
    return result
end

return OrderedSet
