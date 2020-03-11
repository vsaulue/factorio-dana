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
-- * order: Order of elements (=output).
--
-- Methods:
-- * insertElement: Inserts a new element at any place that optimizes the coupling score.
--
local CouplingScoreOptimizer = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local computeCouplingScore

-- Metatable of the CouplingScoreOptimizer class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Inserts a new element at any place that optimizes the coupling score.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        -- * newElement: Element to add.
        --
        insertAnywhere = function(self, newElement)
            local optimalScore = -math.huge
            local optimalPos = nil
            local order = self.order
            local End = order.End
            local it = order.Begin
            while it ~= End do
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
    local End = order.End
    local result = 0
    local forward = order.forward
    local it1 = forward[order.Begin]
    while it1 ~= End do
        local it2 = forward[it1]
        local dist = 1
        while it2 ~= End do
            result = result + (couplings:getCoupling(it1, it2) or 0) / dist
            dist = dist + 1
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
--
-- Returns: `object`, turned into a CouplingScoreOptimizer object.
--
function CouplingScoreOptimizer.new(object)
    assert(object.couplings, "CouplingScoreOptimizer.new: missing mandatory 'couplings' field.")
    assert(object.order, "CouplingScoreOptimizer.new: missing mandatory 'order' field.")
    setmetatable(object, Metatable)
    return object
end

return CouplingScoreOptimizer
