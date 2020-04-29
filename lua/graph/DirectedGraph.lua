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

-- Class representing a weighted directed graph.
--
-- Sybtypes:
-- * Vertex:
-- ** index: Unique identifier.
-- ** inbound[vertexIndex]: Map of inbound Edge, indexed by the index of the source vertex.
-- ** outbound[vertexIndex]: Map of outbound Edge, indexed by the index of the destination vertex.
-- * Edge:
-- ** inbound: Index of the source vertex of this edge.
-- ** outbound: Index of the destination vertex of this edge.
-- ** weight: The weight of this edge. It can be any float, though some algorithms might have stronger requirements (sign, integer...).
--
-- RO Fields:
-- * vertices[vertexIndex]: Map of Vertex objects, indexed by their vertex index.
--
-- Methods: see Metatable.__index.
--
local DirectedGraph = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

local insertEdge

-- Metatable of the DirectedGraph class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a new edge in this graph.
        --
        -- Args:
        -- * self: DirectedGraph object.
        -- * inbound: Index of the source vertex of this edge.
        -- * outbound: Index of the destination vertex of this edge.
        -- * weight: Weight of this edge.
        --
        addEdge = function(self, inbound, outbound, weight)
            local newEdge = ErrorOnInvalidRead.new{
                inbound = inbound,
                outbound = outbound,
                weight = weight,
            }
            insertEdge(self, newEdge)
        end,

        -- Adds a new vertex in this graph.
        --
        -- Args:
        -- * self: DirectedGraph object.
        -- * index: Index of the new vertex.
        --
        addVertexIndex = function(self, index)
            assert(not rawget(self.vertices, index), "DirectedGraph: duplicate vertex index.")
            local result = ErrorOnInvalidRead.new{
                index = index,
                inbound = ErrorOnInvalidRead.new(),
                outbound = ErrorOnInvalidRead.new(),
            }
            self.vertices[index] = result
            return result
        end,

        -- Removes the given edge from a graph.
        --
        -- Args:
        -- * self: DirectedGraph object.
        -- * edge: Edge to remove.
        --
        removeEdge = function(self, edge)
            local vertices = self.vertices
            local srcIndex = edge.inbound
            local srcVertex = vertices[srcIndex]
            local dstIndex = edge.outbound
            local dstVertex = vertices[dstIndex]
            assert(srcVertex.outbound[dstIndex] == edge, "DirectedGraph: invalid edge removal.")
            assert(dstVertex.inbound[srcIndex] == edge, "DirectedGraph: invalid edge removal.")
            srcVertex.outbound[dstIndex] = nil
            dstVertex.inbound[srcIndex] = nil
        end,
    },
}

-- Inserts a new Edge object in this graph.
--
-- Args:
-- * self: DirectedGraph object.
-- * edge: Edge object to insert.
--
insertEdge = function(self, edge)
    local inbound = edge.inbound
    local outbound = edge.outbound
    assert(not rawget(self.vertices[inbound].outbound, outbound), "DirectedGraph: duplicate edge.")
    self.vertices[inbound].outbound[outbound] = edge
    self.vertices[outbound].inbound[inbound] = edge
end

-- Creates a new empty DirectedGraph.
--
-- Returns: the new DirectedGraph object.
--
function DirectedGraph.new()
    local result = {
        vertices = ErrorOnInvalidRead.new(),
    }
    setmetatable(result, Metatable)
    return result
end

return DirectedGraph
