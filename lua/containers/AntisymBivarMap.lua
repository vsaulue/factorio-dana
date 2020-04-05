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
local ReversibleArray = require("lua/containers/ReversibleArray")

-- Class for an antisymmetric, bivariate map.
--
-- For a given finite set E, this class represents a function f: E x E -> float such as:
-- f(x,y) = -f(y,x)
--
-- Said in another way: this is similar to a skew-symmetric matrix, except that indices can be of any type.
--
-- Currently only table indices are supported: strings or numbers might cause undefined behaviour.
--
-- RO fields:
-- * order: ReversibleArray containing all the valid indices.
-- * [idA][idB]: Read the value at the specified indices.
--
local AntisymBivarMap = ErrorOnInvalidRead.new{
    new = nil,
}

local getLowHigh

-- Metatable of the AntisymBivarMap class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a given value at the specified indices.
        --
        -- Args:
        -- * self: Couplings object.
        -- * indexA: First index.
        -- * indexB: Second index.
        -- * delta: Value to add to the coupling coefficient between the given elements.
        --
        addToCoefficient = function(self, indexA, indexB, delta)
            assert(indexA ~= indexB, "AntisymBivarMap: invalid modification (indexA == indexB)")
            local lowElement, highElement = self.order:getLowHighValues(indexA, indexB)
            local value = self[lowElement][highElement] or 0
            if indexA == lowElement then
                value = value + delta
            else
                value = value - delta
            end
            if value == 0 then
                value = nil
            end
            self[lowElement][highElement] = value
        end,

        -- Adds a new element to the set.
        --
        -- Args:
        -- * self: Couplings object.
        -- * element: The new element to add.
        --
        newIndex = function(self, index)
            self.order:pushBack(index)
            self[index] = {}
        end,
    },
}

-- Creates a new empty AntisymBivarMap object.
--
-- Returns the new AntisymBivarMap object.
--
function AntisymBivarMap.new()
    local result = {
        order = ReversibleArray.new(),
	}
    setmetatable(result, Metatable)
    return result
end

return AntisymBivarMap
