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
local ChannelIndexFactory = require("lua/layouts/layer/ChannelIndexFactory")
local ChannelLayer = require("lua/layouts/layer/ChannelLayer")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperSCC = require("lua/hypergraph/algorithms/HyperSCC")
local Iterator = require("lua/containers/utils/Iterator")
local LayerCoordinateGenerator = require("lua/layouts/layer/LayerCoordinateGenerator")
local LayersBuilder = require("lua/layouts/layer/LayersBuilder")
local Logger = require("lua/Logger")
local HyperSrcMinDist = require("lua/hypergraph/algorithms/HyperSrcMinDist")
local OrderedSet = require("lua/containers/OrderedSet")

-- Computes a layer layout for an hypergraph.
--
-- Interesting doc: http://publications.lib.chalmers.se/records/fulltext/161388.pdf
--
-- Stored in global: no.
--
-- RO properties:
-- * channelLayers: Array of ChannelLayer objects (1st channel layer is before the 1st entry layer).
-- * graph: input graph.
-- * layers: Layers object holding the computed layout.
--
-- Methods:
-- * computeCoordinates: Computes the coordinates according to the given parameters.
--
local LayerLayout = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    assignVerticesToLayers = nil, -- implemented later

    avgEntryRank = nil, -- implemented later

    computeCouplingScore = nil, -- implemented later

    countAdjacentCrossings = nil, -- implemented later

    createChannelLayers = nil, -- implemented later

    doInitialOrdering = nil, -- implemented later

    fillChannels = nil, -- implemented later

    -- Metatable of the LayerLayout class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            computeCoordinates = LayerCoordinateGenerator.run,
        },
    },

    normalizeX = nil, -- implemented later

    orderByPermutation = nil, -- implemented later

    orderByBarycenter = nil, -- implemented later

    processEdges = nil, -- implemented later

    sortSlots = nil, -- implemented later
}

-- Splits vertices of the input graph into multiple layers.
--
-- Vertices are assigned in even layers (2nd layer, 4th layer, ...). Odd layers are reserved for edges.
--
-- This function does NOT order the layers themselves.
--
-- Args:
-- * layersBuilder: LayersBuilder object to fill.
-- * graph: DirectedHypergraph to draw.
-- * sourceVertices: set of vertices to place preferably in the first layers.
--
function Impl.assignVerticesToLayers(layersBuilder, graph, sourceVertices)
    -- 1) First layer assignment using distance from source vertices.
    local minDist = HyperSrcMinDist.run(graph, sourceVertices)

    -- 2) Refine layering using topological order of SCCs.
    local depGraph = DirectedHypergraph.new()
    for _,edge in pairs(graph.edges) do
        local edgeDist = minDist.edgeDist[edge.index] or math.huge
        local newEdge = {
            index = edge.index,
            inbound = edge.inbound,
            outbound = {},
        }
        for index,vertexIndex in pairs(edge.outbound) do
            local vertexDist = minDist.vertexDist[vertexIndex] or math.huge
            if vertexDist >= edgeDist then
                table.insert(newEdge.outbound,vertexIndex)
            end
        end
        depGraph:addEdge(newEdge)
    end

    local sccs = HyperSCC.run(depGraph)
    local sccGraph = sccs:makeComponentsDAH()
    local sccToLayer = {}
    for index=#sccs.components,1,-1 do
        local scc = sccs.components[index]
        local sccVertex = sccGraph.vertices[scc]
        if sccVertex then
            local layerId = 2
            for _,edge in pairs(sccVertex.inbound) do
                for _,previousId in pairs(edge.inbound) do
                    local previousLayerId = sccToLayer[previousId]
                    if previousLayerId then
                            layerId = math.max(layerId, previousLayerId + 2)
                    else
                        Logger.error("LayerLayout: Invalid inputs from HyperSCC (wrong topological order, or non-acyclic graph).")
                    end
                end
            end
            sccToLayer[scc] = layerId
            for vertexIndex in pairs(scc) do
                layersBuilder:newVertex(layerId, vertexIndex)
            end
        else
            Logger.error("LayerLayout: Invalid component index")
        end
    end
end

-- Computes the average entry rank of an array of entries.
--
-- Args:
-- * self: LayerLayout object containing the entries.
-- * channelEntries: Array of entries to evaluate.
--
-- Returns: the average rank of the entries (or 0 if the array is empty).
--
function Impl.avgEntryRank(self, channelEntries)
    local result = 0
    local count = channelEntries.count
    if count > 0 then
        local sum = 0
        for i=1,count do
            local entry = channelEntries[i]
            local entryRank = self.layers.reverse[entry.type][entry.index][2]
            sum = sum + entryRank
        end
        result = sum / count
    end
    return result
end

-- Counts the number of crossing/non-crossing pairs of links for consecutive entries.
--
-- Args:
-- * layersBuilder: LayersBuilder object containing the entries.
-- * layerId: Index of the layer containing the entries.
-- * x: Rank of the first entry in the layer (the second entry is the one of rank `x+1`).
-- * direction: Either "forward" or "backward", depending on which sets of links to consider.
--
-- Returns:
-- * The number of crossing pairs.
-- * The number of non-crossing pairs.
--
function Impl.countAdjacentCrossings(layersBuilder, layerId, x, direction)
    local layers = layersBuilder.layers
    local crossingCount = 0
    local nonCrossingCount = 0
    local e1 = layers.entries[layerId][x]
    local e2 = layers.entries[layerId][x+1]
    for link in pairs(layersBuilder.links[direction][e1]) do
        local entry = link:getOtherEntry(e1)
        local xEntry = layers.reverse[entry.type][entry.index][2]
        for otherLink in pairs(layersBuilder.links[direction][e2]) do
            local otherEntry = otherLink:getOtherEntry(e2)
            local xOtherEntry = layers.reverse[otherEntry.type][otherEntry.index][2]
            if xEntry > xOtherEntry then
                crossingCount = crossingCount + 1
            elseif xEntry < xOtherEntry then
                nonCrossingCount = nonCrossingCount + 1
            end
        end
    end
    return crossingCount,nonCrossingCount
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
function Impl.computeCouplingScore(rootOrder, couplings)
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

-- Populates the LayerLayout.channelLayers array with empty ChannelLayer objects.
--
-- Args:
-- * self: the LayerLayout object.
--
function Impl.createChannelLayers(self)
    local count = self.layers.entries.count + 1
    for i=1,count do
        self.channelLayers[i] = ChannelLayer.new()
    end
    self.channelLayers.count = count
end

-- Assigns an initial order to all layers.
--
-- This is a global algorithm, parsing the full layer graph, and using a heuristic to give an initial
-- "good enough" ordering of layers. Local heuristics can refine the work after that.
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
function Impl.doInitialOrdering(layersBuilder)
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
            local score = Impl.computeCouplingScore(rootOrder, couplings)
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

-- Fills channel layers.
--
-- Args:
-- * self: LayerLayout object.
--
function Impl.fillChannels(self, layersBuilder)
    local entries = self.layers.entries
    local backwardLinks = layersBuilder.links.backward
    local forwardLinks = layersBuilder.links.forward
    for i=1,entries.count do
        local layer = entries[i]
        local lowChannelLayer = self.channelLayers[i]
        local highChannelLayer = self.channelLayers[i+1]
        for j=1,layer.count do
            local entry = layer[j]
            for link in pairs(forwardLinks[entry]) do
                highChannelLayer:appendLowEntry(link.channelIndex, entry)
            end
            for link in pairs(backwardLinks[entry]) do
                lowChannelLayer:appendHighEntry(link.channelIndex, entry)
            end
        end
    end
end

-- Normalizes the rank of an entry in a layer.
--
-- Args:
-- * position: Rank to normalize.
-- * length: Length of the layer.
--
-- Returns: The normalized rank.
--
function Impl.normalizeX(position,length)
    return (2 * position - 1) / (2 * length)
end

-- Refines the ordering of layers using the barycenters heuristics.
--
-- Args:
-- * layersBuilder: LayersBuilder object.
--
function Impl.orderByBarycenter(layersBuilder)
    local layersEntries = layersBuilder.layers.entries
    for layerId=1,layersEntries.count do
        local layer = layersEntries[layerId]
        local prevLayerCount = 0
        if layerId > 1 then
            prevLayerCount = layersEntries[layerId-1].count
        end
        local nextLayerCount = 0
        if layerId < layersEntries.count then
            nextLayerCount = layersEntries[layerId+1].count
        end
        local barycenters = {}
        for i=1,layer.count do
            local entry = layer[i]
            local sum = 0
            local count = 0
            for link in pairs(layersBuilder.links.backward[entry]) do
                local otherEntry = link:getOtherEntry(entry)
                local rawX = layersBuilder.layers.reverse[otherEntry.type][otherEntry.index][2]
                count = count + 1
                sum = sum + Impl.normalizeX(rawX, prevLayerCount)
            end
            for link in pairs(layersBuilder.links.forward[entry]) do
                local otherEntry = link:getOtherEntry(entry)
                local rawX = layersBuilder.layers.reverse[otherEntry.type][otherEntry.index][2]
                count = count + 1
                sum = sum + Impl.normalizeX(rawX, nextLayerCount)
            end
            if count == 0 then
                barycenters[entry] = math.huge
            else
                barycenters[entry] = sum / count
            end
        end
        layersBuilder.layers:sortLayer(layerId, barycenters)
    end
end

-- Refines the ordering of layers with permutations of adjacent entries.
--
-- Args:
-- * layersBuilder: LayersBuilder object.
--
function Impl.orderByPermutation(layersBuilder)
    local layersEntries = layersBuilder.layers.entries
    for layerId=1,layersEntries.count do
        local layer = layersEntries[layerId]
        repeat
            local hasImproved = false
            for x=1,layer.count-1 do
                local c1,n1 = Impl.countAdjacentCrossings(layersBuilder, layerId, x, "backward")
                local c2,n2 = Impl.countAdjacentCrossings(layersBuilder, layerId, x, "forward")
                local c = c1 + c2
                local n = n1 + n2
                if (c > n) or (c == n and c1 > n1) then
                    layersBuilder.layers:swap(layerId, x, x+1)
                    hasImproved = true
                end
            end
        until not hasImproved
    end
end

-- Assigns hyperedges to layers.
--
-- Args:
-- * layersBuilder: LayersBuilder object to fill.
-- * graph: DirectedHypergraph to draw.
--
function Impl.processEdges(layersBuilder, graph)
    for _,edge in pairs(graph.edges) do
        local layerId = 1
        for _,vertexIndex in pairs(edge.inbound) do
            layerId = math.max(layerId, 1 + layersBuilder.layers.reverse.vertex[vertexIndex][1])
        end
        layersBuilder:newEdge(layerId, edge)
    end
end

-- Sorts the slots of all entries of the layout.
--
-- Args:
-- * self: LayerLayout object.
--
function Impl.sortSlots(self)
    local lCount = self.channelLayers.count
    for lRank=1,lCount do
        local xAvgHigh = ErrorOnInvalidRead.new()
        local xAvgLow = ErrorOnInvalidRead.new()
        local channelLayer = self.channelLayers[lRank]
        for cRank=1,channelLayer.order.count do
            local channelIndex = channelLayer.order[cRank]
            xAvgHigh[channelIndex] = Impl.avgEntryRank(self, channelLayer.highEntries[channelIndex])
            xAvgLow[channelIndex] = Impl.avgEntryRank(self,channelLayer.lowEntries[channelIndex])
        end
        if lRank > 1 then
            local layer = self.layers.entries[lRank-1]
            for eRank=1,layer.count do
                local entry = layer[eRank]
                entry.outboundSlots:sort(xAvgHigh)
            end
        end
        if lRank < lCount then
            local layer = self.layers.entries[lRank]
            for eRank=1,layer.count do
                local entry = layer[eRank]
                entry.inboundSlots:sort(xAvgLow)
            end
        end
    end
end

-- Creates a new layer layout for the given graph.
--
-- Args:
-- * graph: DirectedHypergraph to draw.
-- * sourceVertices: subset of vertex indices from the graph. They'll be placed preferably in first layers.
--
-- Returns: A new LayerLayout object holding the result.
--
function LayerLayout.new(graph,sourceVertices)
    local channelIndexFactory = ChannelIndexFactory.new()
    local layersBuilder = LayersBuilder.new{
        channelIndexFactory = channelIndexFactory
    }
    local result = {
        channelLayers = Array.new(),
        graph = graph,
        layers = layersBuilder.layers,
    }
    setmetatable(result, Impl.Metatable)

    -- 1) Assign vertices, edges to layers & add dummy vertices.
    Impl.assignVerticesToLayers(layersBuilder, graph, sourceVertices)
    Impl.processEdges(layersBuilder, graph)

    -- 2) Order vertices within their layers (crossing minimization).
    Impl.doInitialOrdering(layersBuilder)
    Impl.orderByBarycenter(layersBuilder)
    Impl.orderByPermutation(layersBuilder)

    -- 3) Channel layers & attach points.
    Impl.createChannelLayers(result)
    Impl.fillChannels(result, layersBuilder)
    Impl.sortSlots(result)

    return result
end

return LayerLayout
