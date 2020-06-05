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
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperSCC = require("lua/hypergraph/algorithms/HyperSCC")
local HyperSrcMinDist = require("lua/hypergraph/algorithms/HyperSrcMinDist")
local LayerCoordinateGenerator = require("lua/layouts/layer/coordinates/LayerCoordinateGenerator")
local LayersBuilder = require("lua/layouts/layer/LayersBuilder")
local LayersSorter = require("lua/layouts/layer/sorter/LayersSorter")
local SlotsSorter = require("lua/layouts/layer/SlotsSorter")

local cLogger = ClassLogger.new{className = "LayerLayout"}

local assignEdgesToLayers
local assignVerticesToLayers
local Metatable

-- Computes a layer layout for an hypergraph.
--
-- Interesting doc: http://publications.lib.chalmers.se/records/fulltext/161388.pdf
--
-- RO properties:
-- * channelLayers: Array of ChannelLayer objects (1st channel layer is before the 1st entry layer).
-- * graph: input graph.
-- * layers: Layers object holding the computed layout.
-- * sourceVertices: subset of vertex indices, to place preferably in 1st layers.
--
-- Methods: See Metatable.__index.
--
local LayerLayout = ErrorOnInvalidRead.new{
    -- Creates a new layer layout.
    --
    -- Args:
    -- * object: Table to turn into a LayerLayout object (mandatory fields: 'graph' & 'sourceVertices')
    --
    -- Returns: The argument turned into a LayerLayout object.
    --
    new = function(object)
        local graph = cLogger:assertField(object, "graph")
        local sourceVertices = cLogger:assertField(object, "sourceVertices")

        local channelIndexFactory = ChannelIndexFactory.new()
        local layersBuilder = LayersBuilder.new{
            channelIndexFactory = channelIndexFactory
        }

        -- 1) Assign vertices, edges to layers & add dummy vertices.
        assignVerticesToLayers(layersBuilder, graph, sourceVertices)
        assignEdgesToLayers(layersBuilder, graph)

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

-- Assigns hyperedges to layers.
--
-- Args:
-- * layersBuilder: LayersBuilder object to fill.
-- * graph: DirectedHypergraph to draw.
--
assignEdgesToLayers = function(layersBuilder, graph)
    for _,edge in pairs(graph.edges) do
        local layerId = 1
        for vertexIndex in pairs(edge.inbound) do
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
assignVerticesToLayers = function(layersBuilder, graph, sourceVertices)
    -- 1) First layer assignment using distance from source vertices.
    local minDist = HyperSrcMinDist.run(graph, sourceVertices)

    -- 2) Refine layering using topological order of SCCs.
    local depGraph = DirectedHypergraph.new()
    for _,edge in pairs(graph.edges) do
        local edgeDist = minDist.edgeDist[edge.index] or math.huge
        local newEdge = DirectedHypergraphEdge.new{
            index = edge.index,
            inbound = edge.inbound,
        }
        for vertexIndex in pairs(edge.outbound) do
            local vertexDist = minDist.vertexDist[vertexIndex] or math.huge
            if vertexDist >= edgeDist then
                newEdge.outbound[vertexIndex] = true
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
        cLogger:assert(sccVertex, "Invalid component index")
        local layerId = 2
        for _,edge in pairs(sccVertex.inbound) do
            for previousId in pairs(edge.inbound) do
                local previousLayerId = sccToLayer[previousId]
                cLogger:assert(previousLayerId, "Invalid inputs from HyperSCC (wrong topological order, or non-acyclic graph).")
                layerId = math.max(layerId, previousLayerId + 2)
            end
        end
        sccToLayer[scc] = layerId
        for vertexIndex in pairs(scc) do
            layersBuilder:newVertex(layerId, vertexIndex)
        end
    end
end

return LayerLayout
