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
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperSCC = require("lua/hypergraph/algorithms/HyperSCC")
local LayerCoordinateGenerator = require("lua/layouts/layer/LayerCoordinateGenerator")
local LayersBuilder = require("lua/layouts/layer/LayersBuilder")
local LayersInitialSorter = require("lua/layouts/layer/LayersInitialSorter")
local Logger = require("lua/Logger")
local HyperSrcMinDist = require("lua/hypergraph/algorithms/HyperSrcMinDist")

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
    assignEdgesToLayers = nil, -- implemented later

    assignVerticesToLayers = nil, -- implemented later

    avgEntryRank = nil, -- implemented later

    countAdjacentCrossings = nil, -- implemented later

    countHorizontalLinks = nil, -- implemented later

    -- Metatable of the LayerLayout class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            computeCoordinates = LayerCoordinateGenerator.run,
        },
    },

    minmax = nil, -- implemented later

    normalizeX = nil, -- implemented later

    orderByPermutation = nil, -- implemented later

    orderByBarycenter = nil, -- implemented later

    sortSlots = nil, -- implemented later
}

-- Assigns hyperedges to layers.
--
-- Args:
-- * layersBuilder: LayersBuilder object to fill.
-- * graph: DirectedHypergraph to draw.
--
function Impl.assignEdgesToLayers(layersBuilder, graph)
    for _,edge in pairs(graph.edges) do
        local layerId = 1
        for _,vertexIndex in pairs(edge.inbound) do
            layerId = math.max(layerId, 1 + layersBuilder.layers.reverse.vertex[vertexIndex][1])
        end
        layersBuilder:newEdge(layerId, edge)
    end
end

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

-- Counts the number of links following certain properties in the given set.
--
-- Args:
-- * layers: Layers object containing the entries.
-- * entry: Entry whose links are counted.
-- * lowX: Upper bound for the rank of entries in the first category.
-- * highX: Lower bound for the rank of entries in the second category.
--
-- Returns:
-- * the number of links whose other entry has a rank strictly lower than `lowX`.
-- * the number of links whose other entry has a rank strictly higher than `highX`.
--
function Impl.countHorizontalLinks(layers, entry, lowX, highX, links)
    local low = 0
    local high = 0
    for link in pairs(links[entry]) do
        local otherEntry = link:getOtherEntry(entry)
        local xOther = layers:getPos(otherEntry)[2]
        if xOther > highX then
            high = high + 1
        elseif xOther < lowX then
            low = low + 1
        end
    end
    return low, high
end

-- Counts the number of crossing/non-crossing pairs of links for consecutive entries.
--
-- Args:
-- * layersBuilder: LayersBuilder object containing the entries.
-- * layerId: Index of the layer containing the entries.
-- * x1: Rank of the first entry in the layer (the second entry is the one of rank `x+1`).
-- * isLowerLinks: True if working on the links in the lower channel layer, false for the upper channel.
--
-- Returns:
-- * The number of cuurently crossing pairs.
-- * The number of crossing pairs if the two entries were swapped.
--
function Impl.countAdjacentCrossings(layersBuilder, layerId, x1, isLowerLinks)
    local layers = layersBuilder.layers
    local x2 = x1 + 1
    local crossingCount = 0
    local nonCrossingCount = 0
    local e1 = layers.entries[layerId][x1]
    local e2 = layers.entries[layerId][x2]

    local verticalLinks = layersBuilder.links.forward
    local horizontalLinks = layersBuilder.links.highHorizontal
    if isLowerLinks then
        verticalLinks = layersBuilder.links.backward
        horizontalLinks = layersBuilder.links.lowHorizontal
    end

    -- Vertical<->Vertical crossings.
    local e1v = 0
    for link in pairs(verticalLinks[e1]) do
        local xEntry = layers:getPos(link:getOtherEntry(e1))[2]
        for otherLink in pairs(verticalLinks[e2]) do
            local xOtherEntry = layers:getPos(otherLink:getOtherEntry(e2))[2]
            if xEntry > xOtherEntry then
                crossingCount = crossingCount + 1
            elseif xEntry < xOtherEntry then
                nonCrossingCount = nonCrossingCount + 1
            end
        end
        e1v = e1v + 1
    end

    -- Horizontal<->Horizontal crossings.
    for link in pairs(horizontalLinks[e1]) do
        local ox1 = layers:getPos(link:getOtherEntry(e1))[2]
        local min1,max1 = Impl.minmax(x1,ox1)
        for otherLink in pairs(horizontalLinks[e2]) do
            local ox2 = layers:getPos(otherLink:getOtherEntry(e2))[2]
            if ox1 ~= ox2 and ox2 ~= x1 and ox1 ~= x2 then
                local inter = 0
                if x2 < max1 then
                    inter = inter + 1
                end
                if min1 < ox2 and ox2 < max1 then
                    inter = inter + 1
                end
                if inter == 1 then
                    crossingCount = crossingCount + 1
                else
                    nonCrossingCount = nonCrossingCount + 1
                end
            end
        end
    end

    -- Vertical<->Horizontal crossings.
    local e1low, e1high = Impl.countHorizontalLinks(layers, e1, x1, x2, horizontalLinks)
    local e2low, e2high = Impl.countHorizontalLinks(layers, e2, x1, x2, horizontalLinks)
    local e2v = 0
    for _ in pairs(verticalLinks[e2]) do
        e2v = e2v + 1
    end
    crossingCount = crossingCount + e1v * e2low + e2v * e1high
    nonCrossingCount = nonCrossingCount + e1v * e2high + e2v * e1low

    return crossingCount,nonCrossingCount
end

-- Gets the min & max of two values.
--
-- Args:
-- * a: First value.
-- * b: Second value.
--
-- Returns:
-- * The lowest value of the 2 arguments.
-- * The highest value of the 2 arguments.
function Impl.minmax(a,b)
    local min = a
    local max = b
    if a > b then
        min = b
        max = a
    end
    return min,max
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
    local links = layersBuilder.links
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
        local currentLayerCount = layer.count
        local barycenters = {}
        for i=1,layer.count do
            local entry = layer[i]
            local sum = 0
            local count = 0
            for link in pairs(links.backward[entry]) do
                local rawX = layersBuilder.layers:getPos(link:getOtherEntry(entry))[2]
                count = count + 1
                sum = sum + Impl.normalizeX(rawX, prevLayerCount)
            end
            for link in pairs(links.forward[entry]) do
                local rawX = layersBuilder.layers:getPos(link:getOtherEntry(entry))[2]
                count = count + 1
                sum = sum + Impl.normalizeX(rawX, nextLayerCount)
            end
            for link in pairs(links.lowHorizontal[entry]) do
                local rawX = layersBuilder.layers:getPos(link:getOtherEntry(entry))[2]
                count = count + 1
                sum = sum + Impl.normalizeX(rawX, currentLayerCount)
            end
            for link in pairs(links.highHorizontal[entry]) do
                local rawX = layersBuilder.layers:getPos(link:getOtherEntry(entry))[2]
                count = count + 1
                sum = sum + Impl.normalizeX(rawX, currentLayerCount)
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
                local c1,n1 = Impl.countAdjacentCrossings(layersBuilder, layerId, x, true)
                local c2,n2 = Impl.countAdjacentCrossings(layersBuilder, layerId, x, false)
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

    -- 1) Assign vertices, edges to layers & add dummy vertices.
    Impl.assignVerticesToLayers(layersBuilder, graph, sourceVertices)
    Impl.assignEdgesToLayers(layersBuilder, graph)

    -- 2) Order vertices within their layers (crossing minimization).
    LayersInitialSorter.run(layersBuilder)
    Impl.orderByBarycenter(layersBuilder)
    Impl.orderByPermutation(layersBuilder)

    -- 3) Channel layers (= connection layers between vertex/edge layers).
    local channelLayers = layersBuilder:generateChannelLayers()

    -- 4) Build the new LayerLayout object.
    local result = {
        channelLayers = channelLayers,
        graph = graph,
        layers = layersBuilder.layers,
    }
    setmetatable(result, Impl.Metatable)

    -- 5) Bonus: Little things to make the result slightly less incomprehensible
    Impl.sortSlots(result)

    return result
end

return LayerLayout
