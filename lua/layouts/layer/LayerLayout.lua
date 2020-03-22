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
local LayerCoordinateGenerator = require("lua/layouts/layer/coordinates/LayerCoordinateGenerator")
local LayersBuilder = require("lua/layouts/layer/LayersBuilder")
local LayersSorter = require("lua/layouts/layer/sorter/LayersSorter")
local Logger = require("lua/Logger")
local HyperSrcMinDist = require("lua/hypergraph/algorithms/HyperSrcMinDist")
local SlotsSorter = require("lua/layouts/layer/SlotsSorter")

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

    -- Metatable of the LayerLayout class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            computeCoordinates = LayerCoordinateGenerator.run,
        },
    },
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
    LayersSorter.run(layersBuilder)

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
    SlotsSorter.run(result)

    return result
end

return LayerLayout
