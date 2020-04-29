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

local Metatable

-- Class providing means to generate topological orders of an acyclic DirectedGraph.
--
-- This class enables to choose which vertex to append to the generated order, when such an order
-- is not unique.
--
-- RO Fields:
-- * candidateCallback: Function to call each time a new vertex can be appended to the topological order.
-- * graph: Input DirectedGraph object (must be acyclic).
-- * outdegrees[vertexIndex]: Map giving the current outdegree of a vertex.
--
-- Methods: see Metatable.__index.
--
local TopologicalOrderGenerator = ErrorOnInvalidRead.new{
    -- Creates a new TopologicalOrderGenerator.
    --
    -- Args:
    -- * object: Table to turn into a new TopologicalOrderGenerator object
    --           (must have a 'graph' & 'candidateCallback' field).
    --
    -- Returns: the argument turned into a TopologicalOrderGenerator object.
    --
    new = function(object)
        local graph = object.graph
        assert(graph, "TopologicalOrderGenerator: missing mandatory 'graph' field.")
        local candidateCallback = object.candidateCallback
        assert(candidateCallback, "TopologicalOrderGenerator: missing mandatory 'candidateCallback' field.")

        local outdegrees = ErrorOnInvalidRead.new()
        for vertexIndex,vertex in pairs(graph.vertices) do
            local outdegree = 0
            for _ in pairs(vertex.inbound) do
                outdegree = outdegree + 1
            end
            if outdegree == 0 then
                candidateCallback(vertexIndex)
            end
            outdegrees[vertexIndex] = outdegree
        end

        object.outdegrees = outdegrees
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the TopologicalOrderGenerator class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Selects the next vertex to append to the topological order.
        --
        -- Args:
        -- * self: TopologicalOrderGenerator object.
        -- * vertexIndex: Index of the vertex to append.
        --
        select = function(self, vertexIndex)
            assert(self.outdegrees[vertexIndex] == 0, "TopologicalOrderGenerator: inappropriate selected vertex.")
            local candidateCallback = self.candidateCallback
            local outdegrees = self.outdegrees
            for dstVertex in pairs(self.graph.vertices[vertexIndex].outbound) do
                local outdegree = outdegrees[dstVertex] - 1
                if outdegree == 0 then
                    candidateCallback(dstVertex)
                end
                outdegrees[dstVertex] = outdegree
            end
            outdegrees[vertexIndex] = -1
        end,
    },
}

return TopologicalOrderGenerator
