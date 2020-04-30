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
local Logger = require("lua/logger/Logger")
local ReversibleArray = require("lua/containers/ReversibleArray")

-- Class to hold coupling coefficients between pairs of elements in a set.
--
-- Elements can't be strings, or nil.
--
-- RO Fields:
-- * order: Internal total order of elements, used to avoid duplicating coefficients.
-- * [elemA][elemB]: 2-dim map of coupling coefficient. Constraint: `order[elemA] < order[elemB]`.
--
-- Methods:
-- * addToCoupling: Adds a given value to a specific coefficient.
-- * getCoupling: Gets the coupling coefficient between two elements.
-- * newElement: Adds a new element.
--
local Couplings = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local getLowHigh

-- Metatable of the Couplings class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a given value to a specific coefficient.
        --
        -- Args:
        -- * self: Couplings object.
        -- * elementA: First element.
        -- * elementB: Other element.
        -- * delta: Value to add to the coupling coefficient between the given elements.
        --
        addToCoupling = function(self, elementA, elementB, delta)
            local lowElement, highElement = getLowHigh(self, elementA, elementB)
            local oldValue = self[lowElement][highElement] or 0
            self[lowElement][highElement] = oldValue + delta
        end,

        -- Gets the coupling coefficient between two elements.
        --
        -- Args:
        -- * self: Couplings object.
        -- * elementA: First element.
        -- * elementB: Other element.
        --
        -- Returns: The coupling coefficient between elementA and elementB.
        --
        getCoupling = function(self, elementA, elementB)
            local lowElement, highElement = getLowHigh(self, elementA, elementB)
            return self[lowElement][highElement] or 0
        end,

        -- Adds a new element.
        --
        -- Args:
        -- * self: Couplings object.
        -- * element: The new element to add.
        --
        newElement = function(self, element)
            self.order:pushBack(element)
            self[element] = {}
        end,
    },
}

-- Sorts two elements, according to their internal order in a Couplings object.
--
-- Args:
-- * self: Couplings object.
-- * elementA: First element.
-- * elementB: Other element.
--
-- Returns:
-- * The element with the lower rank in self.order.
-- * The element with the greater rank in self.order.
--
getLowHigh = function(self, elementA, elementB)
    assert(elementA ~= elementB, "Couplings: Invalid coupling access (elementA == elementB).")
    return self.order:getLowHighValues(elementA, elementB)
end

-- Creates a new Couplings object.
--
-- Returns: The new Couplings object.
--
function Couplings.new()
    local result = {
        order = ReversibleArray.new(),
    }
    setmetatable(result, Metatable)
    return result
end

return Couplings
