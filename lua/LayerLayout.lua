-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local DirectedHypergraph = require("lua/DirectedHypergraph")
local HyperSCC = require("lua/HyperSCC")
local Layers = require("lua/Layers")
local Logger = require("lua/Logger")
local HyperSrcMinDist = require("lua/HyperSrcMinDist")

-- Computes a layer layout for an hypergraph.
--
-- Interesting doc: http://publications.lib.chalmers.se/records/fulltext/161388.pdf
--
-- Stored in global: no.
--
-- RO properties:
-- * graph: input graph.
-- * layers: Layers object holding the computed layout.
--
local LayerLayout = {
    new = nil,
}

-- Implementation stuff (private scope).
local Impl = {
    assignVerticesToLayers = nil, -- implemented later

    processEdges = nil, -- implemented later
}

-- Splits vertices of the input graph into multiple layers.
--
-- Vertices are assigned in even layers (2nd layer, 4th layer, ...). Odd layers are reserved for edges.
--
-- This function does NOT order the layers themselves.
--
-- Args:
-- * self: LayerLayout object.
-- * sourceVertices: set of vertices to place preferably in the first layers.
--
function Impl.assignVerticesToLayers(self,sourceVertices)
    -- 1) First layer assignment using distance from source vertices.
    local minDist = HyperSrcMinDist.run(self.graph,sourceVertices)

    -- 2) Refine layering using topological order of SCCs.
    local depGraph = DirectedHypergraph.new()
    for _,edge in pairs(self.graph.edges) do
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
                self.layers:newVertex(layerId, vertexIndex)
            end
        else
            Logger.error("LayerLayout: Invalid component index")
        end
    end
end

-- Assigns hyperedges to layers.
--
-- Args:
-- * self: LayerLayout object.
--
function Impl.processEdges(self)
    for _,edge in pairs(self.graph.edges) do
        local layerId = 1
        for _,vertexIndex in pairs(edge.inbound) do
            layerId = math.max(layerId, 1 + self.layers.reverse.vertex[vertexIndex][1])
        end
        self.layers:newEdge(layerId, edge)
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
    local result = {
        graph = graph,
        layers = Layers.new(),
    }
    Impl.assignVerticesToLayers(result,sourceVertices)
    Impl.processEdges(result)
    return result
end

return LayerLayout
