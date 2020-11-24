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

local AggregatedLinkSelection = require("lua/renderers/AggregatedLinkSelection")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Tree = require("lua/containers/Tree")

local Metatable

-- Class holding the results of a selection request from a renderer object.
--
-- Fields:
-- * edges: Set of edge indices from the input graph.
-- * link: Set of TreeLink node from the layout.
-- * vertices: Set of vertex indices from the input graph.
--
local RendererSelection = ErrorOnInvalidRead.new{
    -- Creates a new RendererSelection object.
    --
    -- Returns: the new RendererSelection object.
    --
    new = function()
        local result = {
            links = ErrorOnInvalidRead.new(),
            nodes = ErrorOnInvalidRead.new{
                hyperEdge = ErrorOnInvalidRead.new(),
                hyperOneToOne = ErrorOnInvalidRead.new(),
                hyperVertex = ErrorOnInvalidRead.new(),
            },
        }
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a RendererSelection object, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        ErrorOnInvalidRead.setmetatable(object.links)
        ErrorOnInvalidRead.setmetatable(object.nodes, nil, ErrorOnInvalidRead.setmetatable)
    end,
}

-- Metatable of the RendererSelection class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Represents the links field as an AggregatedLinkSelection object.
        --
        -- Args:
        -- * self: RendererSelection object.
        --
        -- Returns: An AggregatedLinkSelection object, representing the selected links.
        --
        makeAggregatedLinkSelection = function(self)
            local nodeSets = {}
            for node in pairs(self.links) do
                local linkIndex = node:getRoot().linkIndex
                local map = nodeSets[linkIndex] or ErrorOnInvalidRead.new()
                map[node] = true
                nodeSets[linkIndex] = map
            end
            local result = AggregatedLinkSelection.new()
            for linkIndex,nodes in pairs(nodeSets) do
                local leaves = Tree.getLeavesOfSet(nodes)
                local edgeIndices = ErrorOnInvalidRead.new()
                for leaf in pairs(leaves) do
                    edgeIndices[leaf.edgeIndex] = true
                end
                result[linkIndex] = edgeIndices
            end
            return result
        end
    },
}

return RendererSelection
