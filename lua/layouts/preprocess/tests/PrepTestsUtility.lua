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
local LinkIndex = require("lua/layouts/LinkIndex")
local PrepGraph = require("lua/layouts/preprocess/PrepGraph")
local PrepNodeIndex = require("lua/layouts/preprocess/PrepNodeIndex")

local PrepTestsUtility

-- Utility library for unit tests of the "preprocess" library.
--
PrepTestsUtility = ErrorOnInvalidRead.new{
    -- Turns an array into a set.
    --
    -- Args:
    -- * array: Input array.
    --
    -- Returns: A set containing the values of the array.
    --
    arrayToSet = function(array)
        local result = {}
        for _,value in pairs(array) do
            result[value] = true
        end
        return result
    end,

    -- Asserts that the internal representation of a PrepGraph is valid.
    --
    -- Args:
    -- * prepGraph: PrepGraph to check.
    --
    checkConsistency = function(prepGraph)
        for nodeIndex,node in pairs(prepGraph.nodes) do
            assert(node.index == nodeIndex)
            for linkIndex in pairs(node.outboundSlots) do
                assert(prepGraph.links[linkIndex])
            end
            for linkIndex in pairs(node.inboundSlots) do
                assert(prepGraph.links[linkIndex])
            end
        end
        for linkIndex,leaves in pairs(prepGraph.links) do
            local rootNode = prepGraph.nodes[linkIndex.rootNodeIndex]
            local leafTable
            if linkIndex.isFromRoot then
                leafTable = "inboundSlots"
                assert(rootNode.outboundSlots[linkIndex])
            else
                leafTable = "outboundSlots"
                assert(rootNode.inboundSlots[linkIndex])
            end
            for nodeIndex in pairs(leaves) do
                local leafNode = prepGraph.nodes[nodeIndex]
                assert(leafNode[leafTable][linkIndex])
            end
        end
    end,

    -- Creates a new PrepNodeIndex.
    --
    -- Args:
    -- * isFromRoot: Value of the isFromRoot field.
    -- * rootNodeIndex: Value of the rootNodeIndex field.
    --
    -- Returns: The new PrepNodeIndex object.
    --
    makeLinkIndex = function(isFromRoot, rootNodeIndex)
        return LinkIndex.new{
            isFromRoot = isFromRoot,
            rootNodeIndex = rootNodeIndex,
            symbol = rootNodeIndex,
        }
    end,

    -- Creates a new PrepLinkIndex.
    --
    -- Args:
    -- * type: Value of the type field.
    -- * index: Value of the index field.
    --
    -- Returns: The new PrepLinkIndex object.
    --
    makeNodeIndex = function(type, index)
        return PrepNodeIndex.new{
            type = type,
            index = index
        }
    end,

    -- Creates a PrepGraph.
    --
    -- Args:
    -- * args: table.
    -- **  vertexIndices: Array of string identifier, used to generate "hyperVertex" nodes.
    -- **  edge: array.
    -- ***   id: String identifier (used to generate the "hyperEdge" node).
    -- ***   inbound: Array of vertex string identifier (inputs of this edge).
    -- ***   outbound: Array of vertex string identifier (outputs of this edge).
    --
    -- Returns: The generated PrepGraph.
    --
    makeSampleGraph = function(args)
        local result = PrepGraph.new()
        local nodes = ErrorOnInvalidRead.new()
        for _,id in pairs(args.vertexIndices) do
            nodes[id] = result:newNode(PrepTestsUtility.makeNodeIndex("hyperVertex", id))
        end
        local fromLeaves = {}
        local toLeaves = {}
        for _,edge in pairs(args.edges) do
            local nodeIndex = PrepTestsUtility.makeNodeIndex("hyperEdge", edge.id)
            nodes[edge.id] = result:newNode(nodeIndex)
            for _,vId in pairs(edge.inbound) do
                fromLeaves[vId] = fromLeaves[vId] or {}
                fromLeaves[vId][nodeIndex] = true
            end
            for _,vId in pairs(edge.outbound) do
                toLeaves[vId] = toLeaves[vId] or {}
                toLeaves[vId][nodeIndex] = true
            end
        end
        for vId,leaves in pairs(fromLeaves) do
            local linkIndex = PrepTestsUtility.makeLinkIndex(true, nodes[vId].index)
            result:addLink(linkIndex, leaves)
        end
        for vId,leaves in pairs(toLeaves) do
            local linkIndex = PrepTestsUtility.makeLinkIndex(false, nodes[vId].index)
            result:addLink(linkIndex, leaves)
        end
        return result,nodes
    end,
}

return PrepTestsUtility
