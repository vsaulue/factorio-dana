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

local makeEdgeNodes
local makeLinks
local makeVertexNodes

-- Class to convert a DirectedHypergraph into a PrepGraph.
--
-- Fields:
-- * fromVertexLeaves[vertexIndex]: Set of leaves for the outbound link of a vertex.
-- * hypergraph: Input DirectedHypergraph.
-- * mergedEdgeNodeIndex[edgeIndex] -> PrepNodeIndex. Map giving the node of edges which has been merged to a vertex node.
-- * prepDists[nodeIndex] -> int. Generated map encoding a partial order on the nodes of the PrepGraph.
-- * prepGraph: The generated PrepGraph.
-- * toVertexLeaves[vertexIndex]: Set of leaves for the inbound link of a vertex.
-- * vertexDists[vertexIndex] -> int. Input map encoding the partial order on vertices.
-- * vertexToNodeIndex[vertexIndex] -> PrepNodeIndex. Map giving the index of the node wrapping an input vertex.
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
        local self = {
            fromVertexLeaves = ErrorOnInvalidRead.new(),
            hypergraph = hypergraph,
            mergedEdgeNodeIndex = {},
            prepDists = {},
            prepGraph = PrepGraph.new(),
            toVertexLeaves = ErrorOnInvalidRead.new(),
            vertexDists = vertexDists,
            vertexToNodeIndex = ErrorOnInvalidRead.new(),
        }

        makeVertexNodes(self)
        makeEdgeNodes(self)
        makeLinks(self)

        return self.prepGraph,self.prepDists
    end,
}

-- Creates a node for each edge of the input hypergraph.
--
-- Args:
-- * self: HyperPreprocessor object.
--
makeEdgeNodes = function(self)
    local fromVertexLeaves = self.fromVertexLeaves
    local mergedEdgeNodeIndex = self.mergedEdgeNodeIndex
    local prepDists = self.prepDists
    local prepGraph = self.prepGraph
    local toVertexLeaves = self.toVertexLeaves
    local vertexDists = self.vertexDists

    for edgeIndex,edge in pairs(self.hypergraph.edges) do
        local nodeIndex = mergedEdgeNodeIndex[edgeIndex]

        if not nodeIndex then
            nodeIndex = PrepNodeIndex.new{
                type = "hyperEdge",
                index = edgeIndex,
            }
            local node = prepGraph:newNode(nodeIndex)
            node.orderPriority = 2

            for vertexIndex in pairs(edge.outbound) do
                toVertexLeaves[vertexIndex][nodeIndex] = true
            end
        end

        local dist = 1
        for vertexIndex in pairs(edge.inbound) do
            fromVertexLeaves[vertexIndex][nodeIndex] = true
            dist = math.max(dist, vertexDists[vertexIndex] or math.huge)
        end

        prepDists[nodeIndex] = prepDists[nodeIndex] or dist
    end
end

-- Creates links between vertex & edge nodes.
--
-- Args:
-- * self: HyperPreprocessor object.
--
makeLinks = function(self)
    local fromVertexLeaves = self.fromVertexLeaves
    local prepGraph = self.prepGraph
    local toVertexLeaves = self.toVertexLeaves
    local vertexToNodeIndex = self.vertexToNodeIndex

    for vertexIndex,leaves in pairs(fromVertexLeaves) do
        local linkIndex = LinkIndex.new{
            isFromRoot = true,
            rootNodeIndex = vertexToNodeIndex[vertexIndex],
            symbol = vertexIndex,
        }
        prepGraph:addLink(linkIndex, leaves)
    end
    for vertexIndex,leaves in pairs(toVertexLeaves) do
        local linkIndex = LinkIndex.new{
            isFromRoot = false,
            rootNodeIndex = vertexToNodeIndex[vertexIndex],
            symbol = vertexIndex,
        }
        prepGraph:addLink(linkIndex, leaves)
    end
end

-- Creates a node for each vertex of the input hypergraph.
--
-- Args:
-- * self: HyperPreprocessor object.
--
makeVertexNodes = function(self)
    local fromVertexLeaves = self.fromVertexLeaves
    local mergedEdgeNodeIndex = self.mergedEdgeNodeIndex
    local prepDists = self.prepDists
    local prepGraph = self.prepGraph
    local toVertexLeaves = self.toVertexLeaves
    local vertexDists = self.vertexDists
    local vertexToNodeIndex = self.vertexToNodeIndex

    for vertexIndex,vertex in pairs(self.hypergraph.vertices) do
        local nodeIndex = PrepNodeIndex.new{
            type = "hyperVertex",
            index = vertexIndex,
        }

        -- Inbound processing.
        local firstEdgeIndex,firstEdge = next(vertex.inbound)
        if firstEdgeIndex then
            local edgeOutbound = firstEdge.outbound
            if next(vertex.inbound, firstEdgeIndex) or next(edgeOutbound, next(edgeOutbound)) then
                toVertexLeaves[vertexIndex] = {}
            else
                nodeIndex.type = "hyperOneToOne"
                nodeIndex.edgeIndex = firstEdgeIndex
                mergedEdgeNodeIndex[firstEdgeIndex] = nodeIndex
            end
        end

        vertexToNodeIndex[vertexIndex] = nodeIndex
        prepDists[nodeIndex] = vertexDists[vertexIndex] or math.huge
        prepGraph:newNode(nodeIndex)

        if next(vertex.outbound) then
            fromVertexLeaves[vertexIndex] = {}
        end
    end
end

return HyperPreprocessor