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
local Couplings = require("lua/layouts/layer/Couplings")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Iterator = require("lua/containers/utils/Iterator")
local OrderedSet = require("lua/containers/OrderedSet")
local ReversibleArray = require("lua/containers/ReversibleArray")
local StrictPoset = require("lua/containers/StrictPoset")

-- Helper class for sorting entries in their layers.
--
-- This is a global algorithm, parsing the full layer graph, and using a heuristic to give an initial
-- "good enough" ordering of layers. Local heuristics can refine the work after that.
--
-- Fields:
-- * layersBuilder: LayersBuilder object on which the sorting algorithm is running.
-- * layersSortingData[layerId]: Map of LayerSortingData (internal type), indexed by layer index.
-- * roots: OrderedSet containing the root entries in the layer layout.
--
local LayersInitialSorter = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local addPath
local computeCouplingScore
local createCouplings
local getOrderByHighestCouplingCoefficients
local initNode
local makeRootIfNoPath
local parseInput
local sortLayers
local sortRoots

-- Class for any computation intermediate during the sorting phase.
--
-- Each node will be assigned an X coordinate at some point, used to determine the final position
-- of entries relative to each other.
--
-- A node can either directly represent an entry in the Layer object, or just be an abstract intermediate.
--
-- Fields:
-- * index: Index of the node.
-- * parents: Set of Node.
-- * pathsToRoots[root]: Map of root -> number of paths to this entry.
-- * counts: Total number of paths to all roots (= sum of pathtoRoots values).
--
local Node = ErrorOnInvalidRead.new{
    -- Creates a new Node object.
    --
    -- Args:
    -- * index: Index of the new node.
    --
    -- Returns: the new node object.
    --
    new = function(index)
        assert(index, "LayersInitialSorter.Node: missing mandatory index.")
        return ErrorOnInvalidRead.new{
            index = index,
            parents = ErrorOnInvalidRead.new(),
            pathsToRoots = ErrorOnInvalidRead.new(),
            counts = 0,
        }
    end,
}

-- Layer sorting data.
--
-- Fields:
-- * nodes[nodeIndex]: Map of Node index -> Node object.
-- * processingOrder: StrictPoset of Nodes, holding the dependencies between nodes.
--
local LayerSortingData = ErrorOnInvalidRead.new{
    new = function()
        return ErrorOnInvalidRead.new{
            nodes = ErrorOnInvalidRead.new(),
            processingOrder = StrictPoset.new(),
        }
    end,
}

-- Adds a path between two nodes.
--
-- Args:
-- * childNode: Child node of the path.
-- * parentNode: Source node of the path.
--
addPath = function(childNode, parentNode)
    for root,count in pairs(parentNode.pathsToRoots) do
        local currentValue = rawget(childNode.pathsToRoots, root) or 0
        childNode.pathsToRoots[root] = currentValue + count
    end
    childNode.parents[parentNode.index] = true
    childNode.counts = childNode.counts + parentNode.counts
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
            result = result + (couplings:getCoupling(it1, it2) or 0) / dist
            dist = dist + 1
            it2 = entries[it2]
        end
        it1 = entries[it1]
    end
    return result
end

-- Parses the input Layers object into useful intermediate data.
--
-- Args:
-- * self: LayersInitialSorter object.
--
parseInput = function(self)
    local channelLayers = self.layersBuilder:generateChannelLayers()
    local entries = self.layersBuilder.layers.entries
    local prevNodes = nil
    for layerId=1,entries.count do
        local layerData = LayerSortingData.new()
        local processingOrder = layerData.processingOrder
        local nodes = layerData.nodes
        self.layersSortingData[layerId] = layerData
        local layer = entries[layerId]
        for rank=1,layer.count do
            initNode(layerData, layer[rank])
        end

        -- First pass: process channels with lower & higher entries.
        local lowChannelLayer = channelLayers[layerId]
        local pureLowChannels = ErrorOnInvalidRead.new()
        for channelIndex,lowEntries in pairs(lowChannelLayer.lowEntries) do
            local highEntries = lowChannelLayer.highEntries[channelIndex]
            if lowEntries.count == 0 then
                pureLowChannels[channelIndex] = highEntries
            else
                local newNode = initNode(layerData, ErrorOnInvalidRead.new())
                for i=1,lowEntries.count do
                    local entryNode = prevNodes[lowEntries[i]]
                    addPath(newNode, entryNode)
                end
                for i=1,highEntries.count do
                    local entryNode = nodes[highEntries[i]]
                    addPath(entryNode, newNode)
                    processingOrder:addRelation(newNode, entryNode)
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
                local vertexNode = nodes[vertexEntry]
                makeRootIfNoPath(self, vertexNode)
                for i=1,highEntries.count do
                    local entry = highEntries[i]
                    if entry ~= vertexEntry then
                        local entryNode = nodes[entry]
                        addPath(entryNode, vertexNode)
                        processingOrder:addRelation(vertexNode, entryNode)
                    end
                end
            end
        end

        -- Third pass: turn any unprocessed entry into a node.
        for rank=1,layer.count do
            local entry = layer[rank]
            makeRootIfNoPath(self, nodes[entry])
        end

        prevNodes = nodes
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
    local result = Couplings.new()

    local roots = self.roots
    local it = roots.entries[OrderedSet.Begin]
    while it ~= OrderedSet.End do
        result:newElement(it)
        it = roots.entries[it]
    end

    local entries = self.layersBuilder.layers.entries
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local nodes = self.layersSortingData[layerId].nodes
        for x=1,layer.count do
            local entry = layer[x]
            local node = nodes[entry]
            local count = node.counts
            local sqrCount = count * count
            local it1 = Iterator.new(node.pathsToRoots)
            local it2 = Iterator.new()
            while it1:next() do
                it2:copy(it1)
                while it2:next() do
                    result:addToCoupling(it1.key, it2.key, (it1.value * it2.value) / sqrCount)
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
    local rootGreatestCouplings = {}
    local max = math.max
    local it1 = roots.entries[OrderedSet.Begin]
    while it1 ~= OrderedSet.End do
        for it2,coupling in pairs(couplings[it1]) do
            rootGreatestCouplings[it1] = max(coupling, rootGreatestCouplings[it1] or 0)
            rootGreatestCouplings[it2] = max(coupling, rootGreatestCouplings[it2] or 0)
        end
        result:pushBack(it1)
        it1 = roots.entries[it1]
    end
    result:sort(rootGreatestCouplings)
    return result
end

-- Initializes a new node in the sorter.
--
-- Args:
-- * layerSortingData: LayersInitialSorter object in which the new node will be inserted.
-- * nodeIndex: Index of the new node.
--
initNode = function(layerSortingData, nodeIndex)
    local newNode = Node.new(nodeIndex)
    layerSortingData.nodes[nodeIndex] = newNode
    layerSortingData.processingOrder:insert(newNode)
    return newNode
end

-- Turns an entry into a root if it has no path to an existing root.
--
-- Args:
-- * self: LayersInitialSorter object.
-- * node: Node to turn into a root.
--
makeRootIfNoPath = function(self, node)
    if node.counts == 0 then
        local index = node.index
        self.roots:pushFront(index)
        node.pathsToRoots[index] = 1
        node.counts = 1
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
        local layerData = self.layersSortingData[layerId]
        local positions = ErrorOnInvalidRead.new()
        if layerId > 1 then
            local prevLayer = entries[layerId-1]
            for rank=1,prevLayer.count do
                local entry = prevLayer[rank]
                positions[entry] = rank
            end
        end
        local processingOrder = layerData.processingOrder:makeLinearExtension()
        for pOrderRank=1,processingOrder.count do
            local node = processingOrder[pOrderRank]
            local nodeIndex = node.index
            local rPos = rawget(rootPos, nodeIndex)
            if rPos then
                positions[nodeIndex] = rPos
            else
                local count = 0
                local newPos = 0
                for parentIndex in pairs(node.parents) do
                    count = count + 1
                    newPos = newPos + positions[parentIndex]
                end
                positions[nodeIndex] = newPos / count
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
        layersBuilder = layersBuilder,
        layersSortingData = ErrorOnInvalidRead.new(),
        roots = OrderedSet.new(),
    }

    parseInput(self)
    sortRoots(self)
    sortLayers(self)
end

return LayersInitialSorter
