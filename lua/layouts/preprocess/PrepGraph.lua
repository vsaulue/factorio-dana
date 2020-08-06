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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local PrepNode = require("lua/layouts/preprocess/PrepNode")

local cLogger = ClassLogger.new{className = "PrepGraph"}

local Metatable

-- Class representing a preprocessed graph, sued by layout algorithms.
--
-- The preprocessing step has several uses:
-- * abstraction for the layout algorithms (a PrepGraph can be built from an hypergraph, a graph, ...).
-- * node aggregation.
-- * link aggregation.
--
-- RO Fields:
-- * nodes[prepNodeIndex] -> PrepNode. Map of nodes owned by this graph.
-- * links[prepLinkIndex]: Set of PrepNodeIndex. Map of links owned by this graph.
--
local PrepGraph = ErrorOnInvalidRead.new{
    -- Creates a new PrepGraph object.
    --
    -- Returns: The new PrepGraph object.
    --
    new = function()
        local result = {
            nodes = ErrorOnInvalidRead.new(),
            links = ErrorOnInvalidRead.new(),
        }
        setmetatable(result, Metatable)
        return result
    end,
}

-- Metatable of the PrepGraph class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a new link into this graph.
        --
        -- Args:
        -- * self: PrepGraph object.
        -- * linkIndex: PrepNodeIndex of the new link.
        -- * leafIndices: Set of PrepNodeIndex. Leaves of the new link.
        --
        addLink = function(self, linkIndex, leafIndices)
            local links = self.links
            cLogger:assert(not rawget(links, linkIndex), "Duplicate link index.")
            links[linkIndex] = leafIndices

            local nodes = self.nodes
            local rootSlotsName = "inboundSlots"
            local leafSlotsName = "outboundSlots"
            if linkIndex.isFromRoot then
                rootSlotsName = "outboundSlots"
                leafSlotsName = "inboundSlots"
            end
            nodes[linkIndex.rootNodeIndex][rootSlotsName][linkIndex] = true
            for leafIndex in pairs(leafIndices) do
                nodes[leafIndex][leafSlotsName][linkIndex] = true
            end
        end,

        -- Adds a new node to this graph.
        --
        -- Args:
        -- * self: PrepGraph object.
        -- * index: PrepNodeIndex of the new node.
        --
        -- Returns: The new PrepNode.
        --
        newNode = function(self, index)
            local nodes = self.nodes
            cLogger:assert(not rawget(nodes, index), "Duplicate node index.")

            local result = PrepNode.new{
                index = index,
            }
            nodes[index] = result
            return result
        end,

        -- Creates a new subgraph of this graph.
        --
        -- Args:
        -- * self: PrepGraph object.
        -- * nodeIndices: Set of PrepNodeIndex. Subset of node indices to include in the subgraph.
        --
        -- Returns: A new PrepGraph object, which is a subgraph of `self` containing only the specified nodes.
        --
        newSubgraph = function(self, nodeIndices)
            local result = PrepGraph.new()
            for nodeIndex in pairs(nodeIndices) do
                if rawget(self.nodes, nodeIndex) then
                    result:newNode(nodeIndex)
                end
            end
            for linkIndex,leaves in pairs(self.links) do
                local rootNodeIndex = linkIndex.rootNodeIndex
                if nodeIndices[rootNodeIndex] then
                    local newLeaves = {}
                    for nodeIndex in pairs(leaves) do
                        if nodeIndices[nodeIndex] then
                            newLeaves[nodeIndex] = true
                        end
                    end
                    if next(newLeaves) then
                        result:addLink(linkIndex, newLeaves)
                    end
                end
            end
            return result
        end,
    },
}

return PrepGraph
