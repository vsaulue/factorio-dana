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
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Stack = require("lua/containers/Stack")

local getSCC
local Metatable
local runAlgorithm

-- Computes the Strongly Connected Components (SCC) of a DirectedHypergraph.
--
-- RO properties:
-- * components: Array of SCCs, stored in a reverse topological order. A SCC is a map: vertexIndex -> vertex.
--
-- Methods:
-- * makeComponentsDAH: creates a direct acyclic graph (DAH) of the components.
--
local HyperSCC = ErrorOnInvalidRead.new{
    -- Computes the strongly connected components of a DirectedHypergraph object.
    --
    -- Args:
    -- * directedHypergraph: the DirectedHypergraph object.
    --
    -- Returns: An HyperSCC object, holding the results of the algorithm for the argument.
    --
    run = function(directedHypergraph)
        local result = {
            -- Input graph
            graph = directedHypergraph,
            -- Intermediate results
            tmp = ErrorOnInvalidRead.new(),
            -- Result
            components = Array.new(),
        }
        runAlgorithm(result)
        result.tmp = nil
        setmetatable(result, Metatable)
        return result
    end,
}

-- Metatable of the HyperSCC class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a direct acyclic graph (DAH) of the components.
        --
        -- In normal graphs, an edge is either a cross-edge (so part of a cycle), or inside a SCC (not part of a
        -- cycle). This is not the case for hypergraphs: cross-edges can be part of cycles.  To make an
        -- acyclic graph, they have to be simplified:
        --
        -- For every cross edge, outbound components that are also inbound components are removed from the
        -- outbound set.
        --
        -- Args:
        -- * self: HyperSCC object.
        --
        -- Returns: the DAH graph.
        --
        makeComponentsDAH = function(self)
            local result = DirectedHypergraph.new()
            local vertexToComponent = {}
            for _,component in pairs(self.components) do
                for index,_ in pairs(component) do
                    vertexToComponent[index] = component
                end
                result:addVertexIndex(component)
            end
            for _,edge in pairs(self.graph.edges) do
                local newEdge = DirectedHypergraphEdge.new{
                    index = edge.index,
                }
                local alreadyPlaced = {}
                for vertexIndex in pairs(edge.inbound) do
                    local component = vertexToComponent[vertexIndex]
                    if not alreadyPlaced[component] then
                        alreadyPlaced[component] = true
                        newEdge.inbound[component] = true
                    end
                end
                local outboundCount = 0
                for vertexIndex in pairs(edge.outbound) do
                    local component = vertexToComponent[vertexIndex]
                    if not alreadyPlaced[component] then
                        alreadyPlaced[component] = true
                        newEdge.outbound[component] = true
                    end
                    outboundCount = outboundCount + 1
                end
                if outboundCount > 0 then
                    result:addEdge(newEdge)
                end
            end
            return result
        end
    },
}

-- Runs Tarjan's strongly connected components algorithm.
--
-- See https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm .
--
-- Args:
-- * self: HyperSCC object running this algorithm.
--
runAlgorithm = function(self)
    -- Number of vertices already explored.
    self.tmp.count = 0
    -- Stack of vertices used by the algorithm.
    self.tmp.vstack = Stack.new()
    -- Table storing additional data for each vertex of the graph.
    self.tmp.vtags = {}
    for _,vertex in pairs(self.graph.vertices) do
        if not self.tmp.vtags[vertex.index] then
            getSCC(self, vertex)
        end
    end
end

-- Recursive function of Tarjan's algorithm.
--
-- At the end of this function, the algorithm will either:
-- * build & store the SCC of vertex.
-- * decides that the vertex belongs to the SCC of a vertex previously placed in the stack.
--
-- Args:
-- * self: HyperSCC object running this algorithm.
-- * vertex: Vertex to explore at this step.
--
-- Returns: the tags
--
getSCC = function(self, vertex)
    local tags = ErrorOnInvalidRead.new{
        order = self.tmp.count,
        lowlink = self.tmp.count,
        onStack = true,
    }
    self.tmp.vtags[vertex.index] = tags
    self.tmp.count = self.tmp.count + 1
    self.tmp.vstack:push(vertex)

    for _,edge in pairs(vertex.outbound) do
        for neighbourIndex in pairs(edge.outbound) do
            local ntags = self.tmp.vtags[neighbourIndex]
            if not ntags then
                local neighbour = self.graph.vertices[neighbourIndex]
                ntags = getSCC(self, neighbour)
                tags.lowlink = math.min(tags.lowlink, ntags.lowlink)
            elseif ntags.onStack then
                tags.lowlink = math.min(tags.lowlink, ntags.order)
            end
        end
    end

    if tags.lowlink == tags.order then
        local newComponent = {}
        repeat
            local v = self.tmp.vstack:pop()
            self.tmp.vtags[v.index].onStack = false
            newComponent[v.index] = v
        until v.index == vertex.index
        self.components:pushBack(newComponent)
    end
    return tags
end

return HyperSCC
