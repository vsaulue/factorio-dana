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
local ReversibleArray = require("lua/containers/ReversibleArray")

-- Helper class for sorting entries in their layers.
--
-- This is a global algorithm, parsing the full layer graph, and using a heuristic to give an initial
-- "good enough" ordering of layers. Local heuristics can refine the work after that.
--
-- Fields:
-- * counts[entry]: Map giving the total number of paths to roots of a given entry.
-- * layersBuilder: LayersBuilder object on which the sorting algorithm is running.
-- * pathsToRoots[entry][root]: 2-dim map giving the number of path from `entry` to `root`.
-- * roots: OrderedSet containing the root entries in the layer layout.
--
local LayersInitialSorter = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local addPath
local computeCouplingScore
local computeRootsAndPaths
local createCouplings
local getOrderByHighestCouplingCoefficients
local initNode
local makeRootIfNoPath
local sortLayers
local sortRoots

-- Adds a path between two nodes.
--
-- Args:
-- * self: LayersInitialSorter object.
-- * child: Destination node of the path.
-- * parent: Source node of the path.
--
addPath = function(self, child, parent)
    local pathsToRoots = self.pathsToRoots
    local counts = self.counts
    for parent,weight in pairs(pathsToRoots[parent]) do
        local currentValue = pathsToRoots[child][parent] or 0
        pathsToRoots[child][parent] = currentValue + weight
    end
    counts[child] = counts[child] + counts[parent]
end

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
computeCouplingScore = function(rootOrder, couplings)
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

-- Fills the `paths`, `counts` and `roots` fields of a LayersInitialSorter object.
--
-- Args:
-- * self: LayersInitialSorter object.
--
computeRootsAndPaths = function(self)
    local channelLayers = self.layersBuilder:generateChannelLayers()
    local entries = self.layersBuilder.layers.entries
    local counts = self.counts
    for layerId=1,entries.count do
        local layer = entries[layerId]
        for rank=1,layer.count do
            initNode(self, layer[rank])
        end

        -- First pass: process channels with lower & higher entries.
        local lowChannelLayer = channelLayers[layerId]
        local pureLowChannels = ErrorOnInvalidRead.new()
        for channelIndex,lowEntries in pairs(lowChannelLayer.lowEntries) do
            local highEntries = lowChannelLayer.highEntries[channelIndex]
            if lowEntries.count == 0 then
                pureLowChannels[channelIndex] = highEntries
            else
                local newNode = ErrorOnInvalidRead.new()
                initNode(self, newNode)
                for i=1,lowEntries.count do
                    local entry = lowEntries[i]
                    addPath(self, newNode, entry)
                end
                for i=1,highEntries.count do
                    local entry = highEntries[i]
                    addPath(self, entry, newNode)
                end
            end
        end

        -- Second pass: process channels which have only higher entries.
        for channelIndex,highEntries in pairs(pureLowChannels) do
            local vertexEntry = nil
            for i=1,highEntries.count do
                local entry = highEntries[i]
                if entry.type == "vertex" then
                    vertexEntry = entry
                end
            end
            if vertexEntry then
                makeRootIfNoPath(self, vertexEntry)
                for i=1,highEntries.count do
                    local entry = highEntries[i]
                    if entry ~= vertexEntry then
                        addPath(self, entry, vertexEntry)
                    end
                end
            end
        end

        -- Third pass: turn any unprocessed entry into a node.
        for rank=1,layer.count do
            local entry = layer[rank]
            makeRootIfNoPath(self, entry)
        end
    end
end

-- Computes coupling scores between each roots.
--
-- Args:
-- * self: LayersInitialSorter object.
--
-- Returns: a 2-dim map, giving the coupling between root entries.
--
createCouplings = function(self)
    local result = ErrorOnInvalidRead.new()

    local roots = self.roots
    local it = roots.entries[OrderedSet.Begin]
    while it ~= OrderedSet.End do
        result[it] = {}
        it = roots.entries[it]
    end

    local entries = self.layersBuilder.layers.entries
    for layerId=1,entries.count do
        local layer = entries[layerId]
        for x=1,layer.count do
            local entry = layer[x]
            local count = self.counts[entry]
            local sqrCount = count * count
            local it1 = Iterator.new(self.pathsToRoots[entry])
            local it2 = Iterator.new()
            while it1:next() do
                it2:copy(it1)
                while it2:next() do
                    local prevCoupling = result[it1.key][it2.key] or 0
                    local newCoupling = prevCoupling + (it1.value * it2.value) / sqrCount
                    result[it1.key][it2.key] = newCoupling
                    result[it2.key][it1.key] = newCoupling
                end
            end
        end
    end
    return result
end

-- Order a set of roots by maximum coupling coefficient.
--
-- This function takes the maximum coupling coefficient of each root, then sort them with
-- this value.
--
-- Args:
-- * roots: OrderedSet of roots to consider.
-- * couplings: Coupling coefficients.
--
-- Returns: Array object containing all roots, ordered from their lowest to highest coupling coefficient.
--
getOrderByHighestCouplingCoefficients = function(roots, couplings)
    local result = Array.new()
    local rootGreatestCouplings = ErrorOnInvalidRead.new()
    local max = math.max
    local it = roots.entries[OrderedSet.Begin]
    while it ~= OrderedSet.End do
        local greatestCoupling = 0
        for _,coupling in pairs(couplings[it]) do
            greatestCoupling = max(coupling, greatestCoupling)
        end
        result:pushBack(it)
        rootGreatestCouplings[it] = greatestCoupling
        it = roots.entries[it]
    end
    result:sort(rootGreatestCouplings)
    return result
end

-- Initializes a new node in the sorter.
--
-- Args:
-- * self: LayersInitialSorter object.
-- * entryOrNode: New node.
--
initNode = function(self, entryOrNode)
    self.pathsToRoots[entryOrNode] = {}
    self.counts[entryOrNode] = 0
end

-- Turns an entry into a root if it has no path to an existing root.
--
-- Args:
-- * self: LayersInitialSorter object.
-- * entry: Entry to turn into a root.
--
makeRootIfNoPath = function(self, entry)
    if self.counts[entry] == 0 then
        self.roots:pushFront(entry)
        self.pathsToRoots[entry][entry] = 1
        self.counts[entry] = 1
    end
end

-- Sort each layers according to their coupling to root nodes.
--
-- Layer order is computed by sorting x-coordinates of the entries, computed as follows:
-- * roots: the x-coordinate is the rank in the previous set.
-- * other: the x-coordinate is the barycenter of the linked roots, weighed by path count.
--
-- Args:
-- * self: LayersInitialSorter object.
--
sortLayers = function(self)
    local it = self.roots.entries[OrderedSet.Begin]
    local rootPos = ReversibleArray.new()
    while it ~= OrderedSet.End do
        rootPos:pushBack(it)
        it = self.roots.entries[it]
    end
    local entries = self.layersBuilder.layers.entries
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local positions = {}
        for x=1,layer.count do
            local entry = layer[x]
            local rPos = rawget(rootPos, entry)
            if rPos then
                positions[entry] = rPos
            else
                local newPos = 0
                for rootEntry,coef in pairs(self.pathsToRoots[entry]) do
                    newPos = newPos + coef * rootPos[rootEntry]
                end
                positions[entry] = newPos / self.counts[entry]
            end
        end
        self.layersBuilder.layers:sortLayer(layerId, positions)
    end
end

-- Order roots, by placing pairs with high coupling close together.
--
-- Coupling score inspired from gravity force (coupling = G * m1 * m2)
--
-- Args:
-- * self: LayersInitialSorter object.
--
sortRoots = function(self)
    local couplings = createCouplings(self)
    local roots = self.roots
    local rootProcessingOrder = getOrderByHighestCouplingCoefficients(roots, couplings)

    roots = OrderedSet.new()
    for i=1,rootProcessingOrder.count do
        local root = rootProcessingOrder[i]
        -- Logger.debug(root.index.rawPrototype.name .. ": " .. rootGreatestCouplings[root])
        local optimalScore = -math.huge
        local optimalPos = nil
        local it = OrderedSet.Begin
        while it ~= OrderedSet.End do
            roots:insertAfter(it,root)
            local score = computeCouplingScore(roots, couplings)
            roots:removeAfter(it)
            if score > optimalScore then
                optimalScore = score
                optimalPos = it
            end
            it = roots.entries[it]
        end
        roots:insertAfter(optimalPos, root)
    end
    self.roots = roots
end

-- Runs the sorting algorithm on a LayersBuilder object.
--
-- Args:
-- * layersBuilder: LayersBuilder object.
--
function LayersInitialSorter.run(layersBuilder)
    local self = ErrorOnInvalidRead.new{
        counts = ErrorOnInvalidRead.new(),
        layersBuilder = layersBuilder,
        pathsToRoots = ErrorOnInvalidRead.new(),
        roots = OrderedSet.new(),
    }

    computeRootsAndPaths(self)
    sortRoots(self)
    sortLayers(self)
end

return LayersInitialSorter
