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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Queue = require("lua/containers/Queue")

-- DirectedHypergraph algorithm: computes the minimal distance of all vertices from a given subset.
--
-- Given:
-- * sourceSet: subset of source vertices.
-- * v: a vertex.
-- * e: an edge.
-- this algorithm computes minimal distances as follow:
-- * d(v) = 0 if v belongs to sourceSet
-- * d(e) =     max{d(v) | v belongs to e.inbound}
-- * d(v) = 1 + min{d(e) | v belongs to e.outbound}
--
-- Said in another way: This algorithm computes distances in a breadth-first search, where
-- an edge `e` can be crossed to reach a vertex in `e.outbound` only if ALL vertices from
-- `e.inbound` have already been reached.
--
local HyperSourceShortestDistance = ErrorOnInvalidRead.new{
    -- Runs the algorithm on the given inputs.
    --
    -- Args:
    -- * graph: DirectedHypergraph object on which the algorithm is run.
    -- * sourceSet: subset of vertex indices from graph, from which distances will be computed.
    --
    -- Returns: A map[vertexIndex] -> distance. Unreachable vertices are not set.
    --
    run = function(graph,sourceSet)
        local vertexDist = {}
        local edgeDist = {}

        -- Intermediates
        local edgeQueue = Queue.new()
        local edgeTags = {}

        -- Init
        for index in pairs(sourceSet) do
            vertexDist[index] = 0
        end
        for _,edge in pairs(graph.edges) do
            local unknowns = 0
            for vertexIndex in pairs(edge.inbound) do
                if not vertexDist[vertexIndex] then
                    unknowns = unknowns + 1
                end
            end
            edgeTags[edge.index] = {
                unknowns = unknowns,
            }
            if unknowns == 0 then
                edgeQueue:enqueue(edge)
                edgeDist[edge.index] = 0
            end
        end

        -- Main loop
        while edgeQueue.count > 0 do
            local edge = edgeQueue:dequeue()
            local dist = 1 + edgeDist[edge.index]
            for vertexIndex in pairs(edge.outbound) do
                if not vertexDist[vertexIndex] then
                    vertexDist[vertexIndex] = dist
                    local vertex = graph.vertices[vertexIndex]
                    for _,nextEdge in pairs(vertex.outbound) do
                        local nextIndex = nextEdge.index
                        edgeTags[nextIndex].unknowns = edgeTags[nextIndex].unknowns - 1
                        if edgeTags[nextIndex].unknowns == 0 then
                            edgeDist[nextIndex] = dist
                            edgeQueue:enqueue(nextEdge)
                        end
                    end
                end
            end
        end

        return vertexDist
    end,
}

return HyperSourceShortestDistance
