-- This file is part of Dana.
-- Copyright (C) 2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local PrepGraph = require("lua/layouts/preprocess/PrepGraph")
local PrepNodeIndex = require("lua/layouts/preprocess/PrepNodeIndex")
local LinkIndex = require("lua/layouts/LinkIndex")

-- Algorithm to convert a DirectedHypergraph into a PrepGraph.
--
local HyperPreprocessor = ErrorOnInvalidRead.new{
    -- Creates a PrepGraph & node order from an hypergraph & vertex order.
    --
    -- Args:
    -- * hypergraph: Input DirectedHypergraph.
    -- * vertexDists[vertexIndex] -> int. Map encoding the partial order on vertices.
    --
    -- Returns:
    -- * A PrepGraph corresponding to the input hypergraph.
    -- * Map[nodeIndex] -> int. Map encoding a partial order on the nodes of the PrepGraph.
    --
    run = function(hypergraph, vertexDists)
        local resultGraph = PrepGraph.new()
        local resultDists = {}
        local fromVertexLinkIndices = ErrorOnInvalidRead.new()
        local fromVertexLeaves = ErrorOnInvalidRead.new()
        local toVertexLinkIndices = ErrorOnInvalidRead.new()
        local toVertexLeaves = ErrorOnInvalidRead.new()

        for vertexIndex,vertex in pairs(hypergraph.vertices) do
            local nodeIndex = PrepNodeIndex.new{
                type = "hyperVertex",
                index = vertexIndex,
            }
            resultDists[nodeIndex] = vertexDists[vertexIndex] or math.huge
            resultGraph:newNode(nodeIndex)
            if next(vertex.inbound) then
                toVertexLinkIndices[vertexIndex] = LinkIndex.new{
                    isFromRoot = false,
                    rootNodeIndex = nodeIndex,
                    symbol = vertexIndex,
                }
                toVertexLeaves[vertexIndex] = {}
            end
            if next(vertex.outbound) then
                fromVertexLinkIndices[vertexIndex] = LinkIndex.new{
                    isFromRoot = true,
                    rootNodeIndex = nodeIndex,
                    symbol = vertexIndex,
                }
                fromVertexLeaves[vertexIndex] = {}
            end
        end

        for edgeIndex,edge in pairs(hypergraph.edges) do
            local nodeIndex = PrepNodeIndex.new{
                type = "hyperEdge",
                index = edgeIndex,
            }
            resultGraph:newNode(nodeIndex)
            local dist = 1
            for vertexIndex in pairs(edge.inbound) do
                fromVertexLeaves[vertexIndex][nodeIndex] = true
                dist = math.max(dist, vertexDists[vertexIndex] or math.huge)
            end
            for vertexIndex in pairs(edge.outbound) do
                toVertexLeaves[vertexIndex][nodeIndex] = true
            end
            resultDists[nodeIndex] = dist
        end

        for vertexIndex,linkIndex in pairs(fromVertexLinkIndices) do
            resultGraph:addLink(linkIndex, fromVertexLeaves[vertexIndex])
        end
        for vertexIndex,linkIndex in pairs(toVertexLinkIndices) do
            resultGraph:addLink(linkIndex, toVertexLeaves[vertexIndex])
        end

        return resultGraph,resultDists
    end,
}

return HyperPreprocessor