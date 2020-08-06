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
local Stack = require("lua/containers/Stack")

local getSCC
local Metatable
local runAlgorithm
local visitNeighbour

-- Computes the Strongly Connected Components (SCC) of a PrepGraph.
--
-- RO properties:
-- * components: Array of SCCs, stored in a reverse topological order. A SCC is a map: nodeIndex -> node.
--
local PrepSCC = ErrorOnInvalidRead.new{
    -- Computes the strongly connected components of a PrepGraph object.
    --
    -- Args:
    -- * prepGraph: the PrepGraph object.
    --
    -- Returns: An PrepSCC object, holding the results of the algorithm for the argument.
    --
    run = function(prepGraph)
        local result = ErrorOnInvalidRead.new{
            -- Input graph
            graph = prepGraph,
            -- Intermediate results
            tmp = ErrorOnInvalidRead.new(),
            -- Result
            components = Array.new(),
        }
        runAlgorithm(result)
        result.tmp = nil
        return result
    end,
}

-- Runs Tarjan's strongly connected components algorithm.
--
-- See https://en.wikipedia.org/wiki/Tarjan%27s_strongly_connected_components_algorithm .
--
-- Args:
-- * self: PrepSCC object running this algorithm.
--
runAlgorithm = function(self)
    -- Number of nodes already explored.
    self.tmp.count = 0
    -- Stack of nodes used by the algorithm.
    self.tmp.vstack = Stack.new()
    -- Table storing additional data for each node of the graph.
    self.tmp.vtags = {}
    for nodeIndex,node in pairs(self.graph.nodes) do
        if not self.tmp.vtags[nodeIndex] then
            getSCC(self, node)
        end
    end
end

-- Recursive function of Tarjan's algorithm.
--
-- At the end of this function, the algorithm will either:
-- * build & store the SCC of node.
-- * decides that the node belongs to the SCC of a node previously placed in the stack.
--
-- Args:
-- * self: PrepSCC object running this algorithm.
-- * node: PrepNode to explore at this step.
--
-- Returns: the tags
--
getSCC = function(self, node)
    local tags = ErrorOnInvalidRead.new{
        order = self.tmp.count,
        lowlink = self.tmp.count,
        onStack = true,
    }
    self.tmp.vtags[node.index] = tags
    self.tmp.count = self.tmp.count + 1
    self.tmp.vstack:push(node)

    for linkIndex in pairs(node.outboundSlots) do
        if linkIndex.isFromRoot then
            local leaves = self.graph.links[linkIndex]
            for neighbourIndex in pairs(leaves) do
                visitNeighbour(self, tags, neighbourIndex)
            end
        else
            visitNeighbour(self, tags, linkIndex.rootNodeIndex)
        end
    end

    if tags.lowlink == tags.order then
        local newComponent = {}
        repeat
            local n = self.tmp.vstack:pop()
            self.tmp.vtags[n.index].onStack = false
            newComponent[n.index] = n
        until n.index == node.index
        self.components:pushBack(newComponent)
    end
    return tags
end

visitNeighbour = function(self, srcTags, neighbourIndex)
    local ntags = self.tmp.vtags[neighbourIndex]
    if not ntags then
        local neighbour = self.graph.nodes[neighbourIndex]
        ntags = getSCC(self, neighbour)
        srcTags.lowlink = math.min(srcTags.lowlink, ntags.lowlink)
    elseif ntags.onStack then
        srcTags.lowlink = math.min(srcTags.lowlink, ntags.order)
    end
end

return PrepSCC
