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
-- * insertAround: Inserts a new element right next to an already present element.
-- * insertMany: Inserts new elements in a specific range.
-- * insertManyAnywhere: Inserts new elements at any place that optimizes the coupling score.
--
local CouplingScoreOptimizer = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local computeHalfScoreDelta
local sortByHighestCouplingCoefficient
local swapAndGetDelta

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
            local bestDelta = 0
            local bestPos = lowElem
            local currentDelta = 0
            local order = self.order
            local forward = order.forward
            order:insertAfter(lowElem, newElement)
            local next = forward[newElement]
            while next ~= highElem do
                currentDelta = currentDelta + swapAndGetDelta(self, newElement)
                if currentDelta > bestDelta then
                    bestDelta = currentDelta
                    bestPos = next
                end
                next = forward[newElement]
            end
            order:remove(newElement)
            order:insertAfter(bestPos, newElement)
        end,

        -- Inserts new elements in a specific range.
        --
        -- The elements are not inserted as a block: each one is inserted separately, in a way tha optimizes the score.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        -- * lowElem: First element of the allowed range (newElement must be inserted after it).
        -- * highElem: Last element of the allowed range (newElement must be inserted before it).
        -- * arrayOfElements: Array object, containing the elements to insert. MODIFIED !
        --
        insertMany = function(self, lowElem, highElem, arrayOfElements)
            sortByHighestCouplingCoefficient(arrayOfElements, self.couplings)
            for i=1,arrayOfElements.count do
                self:insert(lowElem, highElem, arrayOfElements[i])
            end
        end,

        -- Inserts new elements at any place that optimizes the coupling score.
        --
        -- The elements are not inserted as a block: each one is inserted separately, in a way tha optimizes the score.
        --
        -- Args:
        -- * self: CouplingScoreOptimizer object.
        -- * arrayOfElements: Array object, containing the elements to insert. MODIFIED !
        --
        insertManyAnywhere = function(self, arrayOfElements)
            local order = self.order
            local Begin = order.Begin
            local End = order.End
            sortByHighestCouplingCoefficient(arrayOfElements, self.couplings)
            for i=1,arrayOfElements.count do
                self:insert(Begin, End, arrayOfElements[i])
            end
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

-- Helper function to compute "half" of the score delta for a swap.
--
-- When swaping two consecutive elements, this function computes the score delta produced by the
-- swap with a specific subset of element (typically, either all elements before the pair, or all
-- elements after the pair).
--
-- The order of a set "fits well" a coupling function if pairs with a high coupling value
-- tend to be close of each other in the set.
--
-- Inspired by gravity forces: a good order minimizes the potential energy:
-- Ep = - sum(G * m1 * m2 / d(m1,m2)) = - sum(couplings(m1,m2) / (r(m1) + r(m2)))
--
-- The score is simply the opposite, and should be maximized (= higher is better):
-- Score = + sum(couplings(m1,m2) / (r(m1) + r(m2)))
--
-- Args:
-- * self: CouplingScoreOptimizer object.
-- * nearElement: An element in the swaped pair (the closest before the swap operation).
-- * farElement: Other element in the swaped pair (the farthest before the swap operation).
-- * list: Structure to iterate through neighbours (see OrderedSet.forward, or backward).
-- * endSentinel: Element/sentinel on which the delta computation should be stopped.
--
-- Returns: The difference in coupling score, with elements between list[nearElement] and endSentinel excluded.
--
computeHalfScoreDelta = function(self, nearElement, farElement, list, endSentinel)
    local radiuses = self.radiuses
    local couplings = self.couplings
    local distDelta = radiuses[nearElement] + radiuses[farElement]

    local result = 0
    local it = list[nearElement]
    local distFromFirst = radiuses[nearElement]

    while it ~= endSentinel do
        local itRadius = radiuses[it]
        distFromFirst = distFromFirst + itRadius

        local couplingDelta = couplings:getCoupling(it, farElement) - couplings:getCoupling(it, nearElement)
        local distMultiplier = distDelta / ((distFromFirst + distDelta) * distFromFirst)
        result = result + distMultiplier * couplingDelta

        distFromFirst = distFromFirst + itRadius
        it = list[it]
    end
    return result
end

-- Swaps two items in self.order, and computes the resulting difference in coupling score.
--
-- Args:
-- * self: CouplingScoreOptimizer object.
-- * first: First element to swap (with self.order.forward[first])
--
-- Returns: The difference in coupling score (newScore - oldScore).
--
swapAndGetDelta = function(self, first)
    local order = self.order
    local forward = order.forward
    local backward = order.backward
    local second = forward[first]

    local result = computeHalfScoreDelta(self, first, second, backward, order.Begin)
    result = result + computeHalfScoreDelta(self, second, first, forward, order.End)

    order:remove(first)
    order:insertAfter(second, first)

    return result
end

-- Sorts an array of elements, by their highest coefficient in a Couplings object.
--
-- Args:
-- * elements: Array of elements to sort.
-- * couplings: Couplings object holding coefficients for the given array of elements.
--
sortByHighestCouplingCoefficient = function(elements, couplings)
    local rootGreatestCouplings = {}
    local max = math.max
    local count = elements.count
    for i=1,count do
        local elemI = elements[i]
        for j=i+1,count do
            local elemJ = elements[j]
            local coupling = couplings:getCoupling(elemI, elemJ)
            rootGreatestCouplings[elemI] = max(coupling, rootGreatestCouplings[elemI] or 0)
            rootGreatestCouplings[elemJ] = max(coupling, rootGreatestCouplings[elemJ] or 0)
        end
    end
    elements:sort(rootGreatestCouplings)
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
