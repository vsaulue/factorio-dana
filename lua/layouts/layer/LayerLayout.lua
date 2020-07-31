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
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperSCC = require("lua/hypergraph/algorithms/HyperSCC")
local LayerCoordinateGenerator = require("lua/layouts/layer/coordinates/LayerCoordinateGenerator")
local LayerLinkIndexFactory = require("lua/layouts/layer/LayerLinkIndexFactory")
local LayersBuilder = require("lua/layouts/layer/LayersBuilder")
local LayersSorter = require("lua/layouts/layer/sorter/LayersSorter")
local SlotsSorter = require("lua/layouts/layer/SlotsSorter")

local cLogger = ClassLogger.new{className = "LayerLayout"}

local assignToLayers
local makeSubgraphEdge
local makeSubgraphWithDists
local Metatable

-- Computes a layer layout for an hypergraph.
--
-- Interesting doc: http://publications.lib.chalmers.se/records/fulltext/161388.pdf
--
-- RO properties:
-- * channelLayers: Array of ChannelLayer objects (1st channel layer is before the 1st entry layer).
-- * graph: input graph.
-- * layers: Layers object holding the computed layout.
-- * vertexDists[vertexIndex] -> int: suggested partial order of vertices.
--
-- Methods: See Metatable.__index.
--
local LayerLayout = ErrorOnInvalidRead.new{
    -- Creates a new layer layout.
    --
    -- Args:
    -- * object: Table to turn into a LayerLayout object (mandatory fields: 'graph' & 'vertexDists')
    --
    -- Returns: The argument turned into a LayerLayout object.
    --
    new = function(object)
        local graph = cLogger:assertField(object, "graph")
        local vertexDists = cLogger:assertField(object, "vertexDists")

        local layersBuilder = LayersBuilder.new{
            linkIndexFactory = LayerLinkIndexFactory.new()
        }

        -- 1) Assign vertices, edges to layers & add dummy vertices.
        assignToLayers(layersBuilder, graph, vertexDists)

        -- 2) Order vertices within their layers (crossing minimization).
        LayersSorter.run(layersBuilder)

        -- 3) Channel layers (= connection layers between vertex/edge layers).
        local channelLayers = layersBuilder:generateChannelLayers()

        -- 4) Build the new LayerLayout object.
        object.channelLayers = channelLayers
        object.layers = layersBuilder.layers
        setmetatable(object, Metatable)

        -- 5) Bonus: Little things to make the result slightly less incomprehensible
        SlotsSorter.run(object)

        return object
    end
}

-- Metatable of the LayerLayout class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Computes the final X/Y coordinates according to the given parameters.
        --
        -- Args:
        -- * self: LayerLayout object.
        -- * parameters: LayoutParameter object.
        --
        computeCoordinates = LayerCoordinateGenerator.run,
    },
}

-- Splits vertices & edges of the input graph into multiple layers.
--
-- Vertices are assigned in even layers (2nd layer, 4th layer, ...). Odd layers are reserved for edges.
--
-- This function does NOT order the layers themselves.
--
-- Args:
-- * layersBuilder: LayersBuilder object to fill.
-- * graph: DirectedHypergraph to draw.
-- * vertexOrder[vertexIndex] -> int: suggested partial order of vertices.
--
assignToLayers = function(layersBuilder, graph, vertexOrder)
    local order = Array.new()

    -- 1) Assign using the topological order of SCCs in the input graph.
    local sccs = HyperSCC.run(graph).components
    for index=sccs.count,1,-1 do
        local scc = sccs[index]
        -- 2) For each SCC sugraph, use vertexOrder to select & remove some "feedback" edges.
        local subgraph = makeSubgraphWithDists(graph, scc, vertexOrder)
        -- 3) Refine the ordering using the topological order on this subgraph.
        local sccs2 = HyperSCC.run(subgraph).components
        for index2=sccs2.count,1,-1 do
            order:pushBack(sccs2[index2])
        end
    end

    local edgeToLayer = {}
    for edgeIndex in pairs(graph.edges) do
        edgeToLayer[edgeIndex] = 1
    end
    for index=1,order.count do
        local scc = order[index]
        local layerId = 2
        for vertexIndex in pairs(scc) do
            local vertex = graph.vertices[vertexIndex]
            for edgeIndex,edge in pairs(vertex.inbound) do
                if not rawget(edge.inbound, vertexIndex) then
                    layerId = math.max(layerId, 1 + edgeToLayer[edgeIndex])
                end
            end
        end
        for vertexIndex in pairs(scc) do
            local vertex = graph.vertices[vertexIndex]
            layersBuilder:newVertex(layerId, vertexIndex)
            for edgeIndex in pairs(vertex.outbound) do
                edgeToLayer[edgeIndex] = math.max(edgeToLayer[edgeIndex], 1 + layerId)
            end
        end
    end
    for edgeIndex,layerId in pairs(edgeToLayer) do
        layersBuilder:newEdge(layerId, graph.edges[edgeIndex])
    end
end

-- Makes an edge for a subgraph, respecting a given partial order on the vertices.
--
-- An edge E in the subgraph is modified such that: max(E.inbound) <= min(E.outbound). This is done by
-- removing any vertex in E.outbound that would break the constraint.
--
-- Args:
-- * edge: Input DirectedHypergraphEdge.
-- * vertices: Set of vertex indices of the subgraph.
-- * vertexOrder[vertexIndex] -> int. Suggested partial order of vertices, used to edit the edges.
--
-- Returns: The generated DirectedHypergraphEdge.
--
makeSubgraphEdge = function(edge, vertices, vertexOrder)
    local inbound = {}
    local outbound = {}
    local result = DirectedHypergraphEdge.new{
        index = edge.index,
        inbound = inbound,
        outbound = outbound,
    }
    local edgeDist = 0
    for vertexIndex in pairs(edge.inbound) do
        if vertices[vertexIndex] then
            inbound[vertexIndex] = true
            edgeDist = math.max(edgeDist, vertexOrder[vertexIndex] or math.huge)
        end
    end
    for vertexIndex in pairs(edge.outbound) do
        if vertices[vertexIndex] and (vertexOrder[vertexIndex] or math.huge) >= edgeDist then
            outbound[vertexIndex] = true
        end
    end
    return result
end

-- Makes a subgraph, editing edges that don't follow a given partial order on the vertices.
--
-- An edge E in the subgraph is modified such that: max(E.inbound) <= min(E.outbound). This is done by
-- removing any vertex in E.outbound that would break the constraint.
--
-- Args:
-- * graph: Input DirectedHypergraph.
-- * vertices: Set of vertex indices of the generated subgraph.
-- * vertexOrder[vertexIndex] -> int. Suggested partial order of vertices, used to edit the edges.
--
-- Returns: The generated DirectedHypergraph.
--
makeSubgraphWithDists = function(graph, vertices, vertexOrder)
    local result = DirectedHypergraph.new()
    local edges = result.edges
    for vertexIndex,vertex in pairs(vertices) do
        result:addVertexIndex(vertexIndex)
        for edgeIndex,edge in pairs(vertex.inbound) do
            if not rawget(edges, edgeIndex) then
                result:addEdge(makeSubgraphEdge(edge, vertices, vertexOrder))
            end
        end
        for edgeIndex,edge in pairs(vertex.outbound) do
            if not rawget(edges, edgeIndex) then
                result:addEdge(makeSubgraphEdge(edge, vertices, vertexOrder))
            end
        end
    end
    return result
end

return LayerLayout
