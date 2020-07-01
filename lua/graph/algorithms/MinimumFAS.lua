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

local Array = require("lua/containers/Array")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ReversibleArray = require("lua/containers/ReversibleArray")

local Metatable
local removeVertex
local runAlgorithm
local sumWeights

-- Computes an approximate solution the minimum Feedback Arc Set (FAS) problem on a DirectedGraph.
--
-- This algorithm runs on weighted graphs: it tries to minimize the total weight of the feedback set (not the edge count).
-- It is only able to run with strictly positive weights. Weights should also be integers (the implementation does not handle
-- rounding errors).
--
-- This is an implementation of the following heuristic (with trivial modifications to work with weights):
-- https://researchrepository.murdoch.edu.au/id/eprint/27510/1/effective_heuristic.pdf
--
-- RO Fields:
-- * graph: Input DirectedGraph.
-- * sequence: A vertex sequence of the graph as a ReversibleArray, inducing a FAS.
--
-- Methods: see Metatable.__index
--
local MinimumFAS = ErrorOnInvalidRead.new{
    -- Computes an approximate minimum FAS solution for the given weighted graph.
    --
    -- Args:
    -- * graph: Graph on which the algorithm must be run (not modified).
    --
    -- Returns: A MinimumFAS object holding the result.
    --
    run = function(graph)
        local result = {
            graph = graph,
            sequence = ReversibleArray.new(),
            -- Temporary private field, holding the algorithm's intermediate values.
            tmp = ErrorOnInvalidRead.new{
                -- Map of indegrees, indexed by vertex indices.
                inDegrees = ErrorOnInvalidRead.new(),
                -- Map of outdegrees, indexed by vertex indices.
                outDegrees = ErrorOnInvalidRead.new(),
                -- Reversible array of vertex indexes, containing vertices that are either sources or sinks.
                sourcesAndSinks = ReversibleArray.new(),
                -- Number of remaining vertices to process (= number of keys in inDegrees & outDegrees).
                remainingVertexCount = nil,
            },
        }
        setmetatable(result, Metatable)

        runAlgorithm(result)
        result.tmp = nil

        return result
    end
}

Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Removes the feedback edges from the input graph.
        --
        -- Args:
        -- * self: MinimumFAS object.
        --
        removeFeedbackEdges = function(self)
            local graph = self.graph
            local vertices = self.graph.vertices
            local order = self.sequence.reverse
            for srcIndex,srcVertex in pairs(vertices) do
                local srcRank = order[srcIndex]
                for dstIndex,edge in pairs(srcVertex.outbound) do
                    if order[dstIndex] < srcRank then
                        graph:removeEdge(edge)
                    end
                end
            end
        end,
    },
}

-- Removes a selected vertex from the intermediate results.
--
-- Args:
-- * self: MinimumFAS object.
-- * vertexIndex: Index of the vertex to remove.
--
removeVertex = function(self, vertexIndex)
    local vertex = self.graph.vertices[vertexIndex]
    local tmp = self.tmp
    local sourcesAndSinks = tmp.sourcesAndSinks
    local outDegrees = tmp.outDegrees
    for inboundVertex,edge in pairs(vertex.inbound) do
        local outDegree = rawget(outDegrees, inboundVertex)
        if outDegree then
            local newDegree = outDegree - edge.weight
            if newDegree == 0 then
                sourcesAndSinks:pushBackIfNotPresent(inboundVertex)
            end
            outDegrees[inboundVertex] = newDegree
        end
    end
    local inDegrees = tmp.inDegrees
    for outboundVertex,edge in pairs(vertex.outbound) do
        local inDegree = rawget(inDegrees, outboundVertex)
        if inDegree then
            local newDegree = inDegree - edge.weight
            if newDegree == 0 then
                sourcesAndSinks:pushBackIfNotPresent(outboundVertex)
            end
            inDegrees[outboundVertex] = newDegree
        end
    end
    inDegrees[vertexIndex] = nil
    outDegrees[vertexIndex] = nil
    tmp.remainingVertexCount = tmp.remainingVertexCount - 1
end

-- Runs the Eades / Lin / Smyth heuristic for minimum FAS.
--
-- Args:
-- * self: MinimumFAS object.
--
runAlgorithm = function(self)
    local graph = self.graph
    local tmp = self.tmp
    local inDegrees = tmp.inDegrees
    local outDegrees = tmp.outDegrees
    local sourcesAndSinks = tmp.sourcesAndSinks

    -- init
    local count = 0
    for vertexIndex,vertex in pairs(graph.vertices) do
        count = count + 1
        local inDegree = sumWeights(vertex.inbound)
        local outDegree = sumWeights(vertex.outbound)
        inDegrees[vertexIndex] = inDegree
        outDegrees[vertexIndex] = outDegree
        if inDegree == 0 or outDegree == 0 then
            sourcesAndSinks:pushBack(vertexIndex)
        end
    end
    tmp.remainingVertexCount = count

    -- main loop
    local sequence = self.sequence
    local sinksOrder = Array.new()
    while tmp.remainingVertexCount > 0 do
        while sourcesAndSinks.count > 0 do
            local vertexIndex = sourcesAndSinks:popBack()
            if outDegrees[vertexIndex] == 0 then
                sinksOrder:pushBack(vertexIndex)
            else
                sequence:pushBack(vertexIndex)
            end
            removeVertex(self, vertexIndex)
        end
        if tmp.remainingVertexCount > 0 then
            local bestVertex = nil
            local highestScore = -math.huge
            for vertex,inDegree in pairs(inDegrees) do
                local score = outDegrees[vertex] - inDegree
                if score > highestScore then
                    bestVertex = vertex
                    highestScore = score
                end
            end
            sequence:pushBack(bestVertex)
            removeVertex(self, bestVertex)
        end
    end

    -- list merging
    for i=sinksOrder.count,1,-1 do
        sequence:pushBack(sinksOrder[i])
    end
end

-- Computes the sum of weights of a map of DirectedGraph.Edge.
--
-- Args:
-- * edgeMap: Map of DirectedGraph.Edge objects (Map keys are ignored).
--
-- Returns: the sum of weights.
--
sumWeights = function(edgeMap)
    local result = 0
    for _,edge in pairs(edgeMap) do
        local weight = edge.weight
        assert(weight > 0, "MinimumFAS: Negative weights are not supported.")
        result = result + weight
    end
    return result
end

return MinimumFAS
