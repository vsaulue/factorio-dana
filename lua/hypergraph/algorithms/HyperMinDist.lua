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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local Parsers
local run

-- DirectedHypergraph algorithm: computes the minimal distance of all vertices from a given subset.
--
-- Given:
-- * sourceSet: subset of source vertices.
-- * v: a vertex.
-- * e: an edge.
-- this algorithm computes minimal distances as follow:
-- * d(v) = 0 if v belongs to sourceSet
-- * d(e) = 1 + max{d(v) | v belongs to e.inbound}
-- * d(v) = min{d(e) | v belongs to e.outbound}
--
-- Said in another way: This algorithm computes distances in a breadth-first search. An argument controls
-- whether edges are crossed when any vertex of their input set is reached, or to wait until all vertices
-- of the input sets are reached.
--
local HyperMinDist = ErrorOnInvalidRead.new{
    -- Computes the distances from a set of source vertices.
    --
    -- This function does forward parsing: edges are crossed from inbound to outbound vertices.
    -- It computes the vertices that can be reached from the input set.
    --
    -- Args:
    -- * graph: DirectedHypergraph object on which the algorithm is run.
    -- * sourceSet: subset of vertex indices from graph, from which distances will be computed.
    -- * crossOnFirstInput: True to cross an edge when the 1st inbound vertex is reached.
    --                      False to cross only when all inbound vertices are reached.
    -- * maxDepth: Maximum depth for the lookup.
    --
    -- Returns:
    -- * A map[vertexIndex] -> distance. Unreachable vertices are not set.
    -- * A map[edgeIndex] -> distance. Unreachable edges are not set.
    --
    fromSource = function(graph, sourceSet, crossOnFirstInput, maxDepth)
        return run(graph, sourceSet, Parsers.fromSource, crossOnFirstInput, maxDepth)
    end,

    -- Computes the distances from a set of source vertices.
    --
    -- This function does backward parsing: edges are crossed from outbound to inbound vertices.
    -- It computes the vertices that can reach the input set.
    --
    -- Args:
    -- * graph: DirectedHypergraph object on which the algorithm is run.
    -- * destSet: subset of vertex indices from graph, from which distances will be computed.
    -- * crossOnFirstInput: True to cross an edge when the 1st inbound vertex is reached.
    --                      False to cross only when all inbound vertices are reached.
    -- * maxDepth: Maximum depth for the lookup.
    --
    -- Returns:
    -- * A map[vertexIndex] -> distance. Unreachable vertices are not set.
    -- * A map[edgeIndex] -> distance. Unreachable edges are not set.
    --
    toDest = function(graph, destSet, crossOnFirstInput, maxDepth)
        return run(graph, destSet, Parsers.toDest, crossOnFirstInput, maxDepth)
    end,
}

-- Instances of parsers used to go through the graph.
--
-- Fields:
-- * srcField: source field name in DirectedHypergraph Edge & Vertex.
-- * destField: destination field name in DirectedHypergraph Edge & Vertex.
--
Parsers = ErrorOnInvalidRead.new{
    -- Parser for forward traversal.
    fromSource = ErrorOnInvalidRead.new{
        srcField = "inbound",
        destField = "outbound",
    },

    -- Parser for backward traversal.
    toDest = ErrorOnInvalidRead.new{
        srcField = "outbound",
        destField = "inbound",
    },
}

-- Computes the distances from a set of source vertices.
--
-- Args:
-- * graph: DirectedHypergraph object on which the algorithm is run.
-- * vertexSet: subset of vertex indices from graph, from which distances will be computed.
-- * parser: Parser object used to go through the graph.
-- * crossOnFirstInput: True to cross an edge when the 1st inbound vertex is reached.
--                      False to cross only when all inbound vertices are reached.
-- * maxDepth: Maximum depth for the lookup.
--
-- Returns:
-- * A map[vertexIndex] -> distance. Unreachable vertices are not set.
-- * A map[edgeIndex] -> distance. Unreachable edges are not set.
--
run = function(graph, vertexSet, parser, crossOnFirstInput, maxDepth)
    maxDepth = maxDepth or math.huge
    local srcField = parser.srcField
    local destField = parser.destField

    local vertexDist = {}
    local edgeDist = {}
    local edgeUnknowns = {}
    local currentEdges = Array.new()
    local nextEdges = Array.new()

    -- Init
    for index in pairs(vertexSet) do
        vertexDist[index] = 0
    end
    for _,edge in pairs(graph.edges) do
        local unknowns = 0
        local reached = false
        for vertexIndex in pairs(edge[srcField]) do
            if vertexDist[vertexIndex] then
                reached = true
            else
                unknowns = unknowns + 1
            end
        end
        if unknowns == 0 or (crossOnFirstInput and reached) then
            currentEdges:pushBack(edge)
        elseif crossOnFirstInput then
            unknowns = 1
        end
        edgeUnknowns[edge.index] = unknowns
    end

    -- Main loop
    local depth = 1
    while currentEdges.count > 0 and depth <= maxDepth do
        for i=1,currentEdges.count do
            local edge = currentEdges[i]
            edgeDist[edge.index] = depth
            for vertexIndex in pairs(edge[destField]) do
                if not vertexDist[vertexIndex] then
                    vertexDist[vertexIndex] = depth
                    local vertex = graph.vertices[vertexIndex]
                    for _,nextEdge in pairs(vertex[destField]) do
                        local nextIndex = nextEdge.index
                        edgeUnknowns[nextIndex] = edgeUnknowns[nextIndex] - 1
                        if edgeUnknowns[nextIndex] == 0 then
                            nextEdges:pushBack(nextEdge)
                        end
                    end
                end
            end
        end

        local tmp = nextEdges
        nextEdges = currentEdges
        currentEdges = tmp

        nextEdges.count = 0
        depth = depth + 1
    end

    return vertexDist,edgeDist
end

return HyperMinDist
