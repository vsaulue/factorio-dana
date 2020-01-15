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

local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")

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
-- * pushBack: Adds a new value at the end of this ReversibleArray.
-- * pushBackIfNotPresent: Append a value if it's not already present, else does nothing.
--
local ReversibleArray = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    -- Metatable of the LayerLink class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
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
        },
    },
}

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
