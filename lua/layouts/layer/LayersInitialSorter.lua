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

local Array = require("lua/containers/Array")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Iterator = require("lua/containers/utils/Iterator")
local OrderedSet = require("lua/containers/OrderedSet")

-- Helper class for sorting entries in their layers.
--
-- This is a global algorithm, parsing the full layer graph, and using a heuristic to give an initial
-- "good enough" ordering of layers. Local heuristics can refine the work after that.
--
local LayersInitialSorter = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
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
-- * order: OrderedSet object.
-- * couplings[m1,m2]: a table giving the coupling values for each pair in `order`
--
-- Returns: a score (higher is better).
--
local function computeCouplingScore(rootOrder, couplings)
    local result = 0
    local entries = rootOrder.entries
    local it1 = entries[OrderedSet.Begin]
    while it1 ~= OrderedSet.End do
        local it2 = entries[it1]
        local dist = 1
        while it2 ~= OrderedSet.End do
            result = result + (couplings[it1][it2] or 0) / dist
            dist = dist + 1
            it2 = entries[it2]
        end
        it1 = entries[it1]
    end
    return result
end

-- Assigns an initial order to all layers.
--
-- Algorithm works as follow:
-- 1a) Computes roots (entries with no backward links)
-- 1b) For non-roots, compute the number of paths to each roots.
-- 2)  Compute a "coupling" value between each root pairs (great coupling <=> many entries have paths to these roots).
-- 3)  Order the roots using couplings (try to place pairs with high couplings close of each other).
-- 4)  Compute order of non-roots, using barycenter of the roots they're linked to.
--
-- Args:
-- * layersBuilder: LayerBuilder object.
--
function LayersInitialSorter.run(layersBuilder)
    -- 1a & 1b) Computes root entries, and number of paths to roots for other entries.
    local paths = {}
    local counts = {}
    local roots = {}
    local layersEntries = layersBuilder.layers.entries
    for layerId=1,layersEntries.count do
        local layer = layersEntries[layerId]
        for x=1,layer.count do
            local entry = layer[x]
            paths[entry] = {}
            counts[entry] = 0
            for link in pairs(layersBuilder.links.backward[entry]) do
                local otherEntry = link:getOtherEntry(entry)
                for parent,weight in pairs(paths[otherEntry]) do
                    local currentValue = paths[entry][parent] or 0
                    paths[entry][parent] = currentValue + weight
                end
                counts[entry] = counts[entry] + counts[otherEntry]
            end
            if counts[entry] == 0 then
                roots[entry] = true
                paths[entry][entry] = 1
                counts[entry] = 1
            end
        end
    end

    -- 2) Compute coupling scores between each roots.
    -- Coupling score inspired from gravity force (coupling = G * m1 * m2)
    local couplings = {}
    for entry in pairs(roots) do
        couplings[entry] = {}
    end
    for layerId=1,layersEntries.count do
        local layer = layersEntries[layerId]
        for x=1,layer.count do
            local entry = layer[x]
            local sqrCount = counts[entry] * counts[entry]
            local it1 = Iterator.new(paths[entry])
            local it2 = Iterator.new()
            while it1:next() do
                it2:copy(it1)
                while it2:next() do
                    local prevCoupling = couplings[it1.key][it2.key] or 0
                    local newCoupling = prevCoupling + (it1.value * it2.value) / sqrCount
                    couplings[it1.key][it2.key] = newCoupling
                    couplings[it2.key][it1.key] = newCoupling
                end
            end
        end
    end

    -- 3) Order roots, by placing pairs with high coupling close together.
    -- 3.1: process roots by their highest coupling coefficients
    local rootProcessingOrder = Array.new()
    local rootGreatestCouplings = {}
    local max = math.max
    for root in pairs(roots) do
        local greatestCoupling = 0
        for _,coupling in pairs(couplings[root]) do
            greatestCoupling = max(coupling, greatestCoupling)
        end
        rootProcessingOrder:pushBack(root)
        rootGreatestCouplings[root] = greatestCoupling
    end
    rootProcessingOrder:sort(rootGreatestCouplings)

    -- 3.2: Main algorithm
    local rootOrder = OrderedSet.new()
    for i=1,rootProcessingOrder.count do
        local root = rootProcessingOrder[i]
        -- Logger.debug(root.index.rawPrototype.name .. ": " .. rootGreatestCouplings[root])
        local optimalScore = -math.huge
        local optimalPos = nil
        local it = OrderedSet.Begin
        while it ~= OrderedSet.End do
            rootOrder:insertAfter(it,root)
            local score = computeCouplingScore(rootOrder, couplings)
            rootOrder:removeAfter(it)
            if score > optimalScore then
                optimalScore = score
                optimalPos = it
            end
            it = rootOrder.entries[it]
        end
        rootOrder:insertAfter(optimalPos, root)
    end

    -- 4) Computes order of each layers
    -- roots: the x-coordinate is the rank in the previous set.
    -- other: the x-coordinate is the barycenter of the linked roots, weighed by path count.
    -- Layer order is computed by sorting x-coordinates of the entries.
    local it = rootOrder.entries[OrderedSet.Begin]
    local rootPos = {}
    local pos = 1
    while it ~= OrderedSet.End do
        rootPos[it] = pos
        pos = pos + 1
        it = rootOrder.entries[it]
    end
    for layerId=1,layersEntries.count do
        local layer = layersEntries[layerId]
        local positions = {}
        for x=1,layer.count do
            local entry = layer[x]
            if rootPos[entry] then
                positions[entry] = rootPos[entry]
            else
                local newPos = 0
                for rootEntry,coef in pairs(paths[entry]) do
                    newPos = newPos + coef * rootPos[rootEntry]
                end
                positions[entry] = newPos / counts[entry]
            end
        end
        layersBuilder.layers:sortLayer(layerId,positions)
    end
end

return LayersInitialSorter
