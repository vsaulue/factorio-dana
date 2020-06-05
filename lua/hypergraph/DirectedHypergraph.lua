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

local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local DirectedHypergraphVertex = require("lua/hypergraph/DirectedHypergraphVertex")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "DirectedHypergraph"}

local initVertex
local Metatable

-- Class implementing a directed hypergraph.
--
-- The directed hypergraph is a generalization of the hypergraph, where an edge has 2 sets of vertices
-- (named "in" & "out" in this implementation) instead of one.
--
-- Visual example: https://i.stack.imgur.com/pWMW5.png
--
-- Fields:
-- * edges: map[edgeIndex] -> DirectedHypergraphEdge.
-- * vertices: map[vertexIndex] -> DirectedHypergraphVertex.
--
-- Methods: see Metatable.__index
--
local DirectedHypergraph = ErrorOnInvalidRead.new{
    -- Creates a new DirectedHypergraph object.
    --
    -- Returns: A new empty hypergraph.
    --
    new = function()
        local result = {
            edges = ErrorOnInvalidRead.new(),
            vertices = ErrorOnInvalidRead.new(),
        }
        setmetatable(result, Metatable)
        return result
    end,

    -- Assigns the metatable of DirectedHypergraph class to the argument.
    --
    -- Intended to restore metatable of objects in the global table.
    --
    -- Args:
    -- * object: Table to modify.
    setmetatable = function(object)
        setmetatable(object, Metatable)

        ErrorOnInvalidRead.setmetatable(object.edges)
        for _,edge in pairs(object.edges) do
            DirectedHypergraphEdge.setmetatable(edge)
        end

        ErrorOnInvalidRead.setmetatable(object.vertices)
        for _,vertex in pairs(object.vertices) do
            DirectedHypergraphVertex.setmetatable(vertex)
        end
    end,
}

-- Metatable of the DirectedHypergraph class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a new edge to an hypergraph
        --
        -- Args:
        -- * self: Hypergraph object.
        -- * newEdge: new edge (must have an "index" field).
        --
        addEdge = function(self, newEdge)
            local index = newEdge.index
            if not rawget(self.edges, index) then
                self.edges[index] = newEdge
                if newEdge.inbound then
                    for vertexIndex in pairs(newEdge.inbound) do
                        local vertex = initVertex(self,vertexIndex)
                        vertex.outbound[index] = newEdge
                    end
                end
                if newEdge.outbound then
                    for vertexIndex in pairs(newEdge.outbound) do
                        local vertex = initVertex(self,vertexIndex)
                        vertex.inbound[index] = newEdge
                    end
                end
            else
                cLogger:error("Duplicate edge index in Hypergraph (index: " .. index .. ").")
            end
        end,

        -- Adds a new vertex to the graph.
        --
        -- Args:
        -- * self: Hypergraph object.
        -- * vertexIndex: index of the new vertex.
        --
        addVertexIndex = function(self, vertexIndex)
            initVertex(self, vertexIndex)
        end,
    },
}

-- Gets (or creates if needed) the vertex with the specified index.
--
-- Args:
-- * self: The Hypergraph object.
-- * vertexIndex: index of the vertex to get (or create).
--
-- Returns: The Vertex object of the given index.
--
initVertex = function(self,vertexIndex)
    local result = rawget(self.vertices, vertexIndex)
    if not result then
        result = DirectedHypergraphVertex.new{
            index = vertexIndex,
        }
        self.vertices[vertexIndex] = result
    end
    return result
end

return DirectedHypergraph
