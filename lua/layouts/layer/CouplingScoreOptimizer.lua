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

-- Helper class to determine a "good" order for entries.
--
-- The principle is to insert items one by one, in a way that maximizes some score.
--
-- RO Fields:
-- * couplings: Couplings object holding the coefficients between each elements.
-- * radiuses[elem]: Map giving the radius of each element.
-- * order: Order of elements (=output).
--
-- Methods:
-- * generatePositions: Generates a map giving the position of each entry.
-- * insert: Inserts a given element in a specific range.
-- * insertAnywhere: Inserts a new element at any place that optimizes the coupling score.
-- * insertAround: Inserts a new element right next to an already present element.
--
local CouplingScoreOptimizer = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local computeCouplingScore

-- Metatable of the CouplingScoreOptimizer class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a map giving the position of each entry.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        --
        -- Returns: A map indexed by entries, giving their position in self.order.
        --
        generatePositions = function(self)
            local result = ErrorOnInvalidRead.new()
            local order = self.order
            local forward = order.forward
            local i = 1
            local it = forward[order.Begin]
            local End = order.End
            while it ~= End do
                result[it] = i
                it = forward[it]
                i = i + 1
            end
            return result
        end,

        -- Inserts a given element in a specific range.
        --
        -- The element is placed at the position in the allowed range that maximizes the coupling score.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        -- * lowElem: First element of the allowed range (newElement must be inserted after it).
        -- * highElem: Last element of the allowed range (newElement must be inserted before it).
        -- * newElement: New element to insert.
        --
        insert = function(self, lowElem, highElem, newElement)
            local optimalScore = -math.huge
            local optimalPos = nil
            local order = self.order
            local it = lowElem
            while it ~= highElem do
                order:insertAfter(it, newElement)
                local score = computeCouplingScore(self)
                order:remove(newElement)
                if score > optimalScore then
                    optimalScore = score
                    optimalPos = it
                end
                it = order.forward[it]
            end
            order:insertAfter(optimalPos, newElement)
        end,

        -- Inserts a new element at any place that optimizes the coupling score.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        -- * newElement: Element to add.
        --
        insertAnywhere = function(self, newElement)
            local order = self.order
            self:insert(order.Begin, order.End, newElement)
        end,

        -- Inserts a new element right next to an already present element.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        -- * placedElement: Element already present in the optimizer.
        -- * newElement: Element to add next to placedElement.
        --
        insertAround = function(self, placedElement, newElement)
            local order = self.order
            self:insert(order.backward[placedElement], order.forward[placedElement], newElement)
        end,
    },
}

-- Computes a score indicating if the order of a set "fits well" the given couplings.
--
-- The order of a set "fits well" a coupling function if pairs with a high coupling value
-- tends to be close of each other in the set.
--
-- Inspired by gravity forces: a good order minimizes the potential energy:
-- Ep = - sum(G * m1 * m2 / d(m1,m2)) = - sum(couplings(m1,m2)/d(m1,m2))
--
-- Args:
-- * self: CouplingScoreOptimizer object.
--
-- Returns: a score (higher is better).
--
computeCouplingScore = function(self)
    local order = self.order
    local couplings = self.couplings
    local radiuses = self.radiuses
    local End = order.End
    local result = 0
    local forward = order.forward
    local it1 = forward[order.Begin]
    while it1 ~= End do
        local it2 = forward[it1]
        local dist = radiuses[it1]
        while it2 ~= End do
            local radius2 = radiuses[it2]
            dist = dist + radius2
            result = result + (couplings:getCoupling(it1, it2) or 0) / dist
            dist = dist + radius2
            it2 = forward[it2]
        end
        it1 = forward[it1]
    end
    return result
end

-- Creates a new CouplingScoreOptimizer object.
--
-- Args:
-- * object: Table to turn into a CouplingScoreOptimizer object. Must have the following fields:
-- ** couplings
-- ** order
-- ** radiuses
--
-- Returns: `object`, turned into a CouplingScoreOptimizer object.
--
function CouplingScoreOptimizer.new(object)
    local order = object.order
    assert(object.couplings, "CouplingScoreOptimizer.new: missing mandatory 'couplings' field.")
    assert(order, "CouplingScoreOptimizer.new: missing mandatory 'order' field.")
    assert(object.radiuses, "CouplingScoreOptimizer.new: missing mandatory 'radiuses' field.")
    setmetatable(object, Metatable)
    return object
end

return CouplingScoreOptimizer
