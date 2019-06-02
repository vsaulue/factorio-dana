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
local Logger = require("lua/Logger")
local HyperSrcMinDist = require("lua/HyperSrcMinDist")

-- Computes a layer layout for an hypergraph.
--
-- Interesting doc: http://publications.lib.chalmers.se/records/fulltext/161388.pdf
--
-- Stored in global: no.
--
-- Fields:
-- * layers: 2-dim array of vertex indices (1st index: layer index, 2nd index: vertex position in layer).
--
local LayerLayout = {
    new = nil,
}

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
        layers = {},
    }
    local minDist = HyperSrcMinDist.run(graph,sourceVertices)

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
            local layerId = 1
            for _,edge in pairs(sccVertex.inbound) do
                for _,previousId in pairs(edge.inbound) do
                    local previousLayerId = sccToLayer[previousId]
                    if previousLayerId then
                            layerId = math.max(layerId, previousLayerId + 1)
                    else
                        Logger.error("LayerLayout: Invalid inputs from HyperSCC (wrong topological order, or non-acyclic graph).")
                    end
                end
            end
            sccToLayer[scc] = layerId
            result.layers[layerId] = result.layers[layerId] or {}
            for vertexIndex in pairs(scc) do
                table.insert(result.layers[layerId], vertexIndex)
            end
        else
            Logger.error("LayerLayout: Invalid component index")
        end
    end
    return result
end

return LayerLayout
