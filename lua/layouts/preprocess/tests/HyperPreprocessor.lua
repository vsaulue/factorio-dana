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

local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local HyperPreprocessor = require("lua/layouts/preprocess/HyperPreprocessor")
local TestUtils = require("lua/layouts/preprocess/tests/PrepTestsUtility")

local newLeavesSet
local newSampleGraph

describe("HyperPreprocessor", function()
    it(".run()", function()
        local inputGraph = newSampleGraph()
        local vertexDists = {
            a = 1,
            b = 2,
            c = 2,
            d = 3,
            e = 3,
        }
        local prepGraph,prepDists = HyperPreprocessor.run(inputGraph, vertexDists)
        TestUtils.checkConsistency(prepGraph)

        -- Map[nodeType][nodeIndex]: expected dist.
        local ExpectedNodes = {
            hyperEdge = {
                ["a -> bc"] = 1,
                ["ac -> bd"] = 2,
                ["b -> d"] = 2,
            },
            hyperOneToOne = {
                e = 3,
            },
            hyperVertex = vertexDists,
        }

        local nodes = {}
        local nodeCount = 0
        for nodeIndex,node in pairs(prepGraph.nodes) do
            local expectedDist = ExpectedNodes[nodeIndex.type][nodeIndex.index]
            assert.is_not_nil(expectedDist)
            assert.are.equals(prepDists[nodeIndex], expectedDist)
            local expectedPriority = 1
            if nodeIndex.type == "hyperEdge" then
                expectedPriority = 2
            end
            assert.are.equals(node.orderPriority, expectedPriority)
            nodes[nodeIndex.index] = node
            nodeCount = nodeCount + 1
        end
        assert.are.equals(nodeCount, 8)

        -- Map[isFromRoot][nodeIndex] -> Array of edge index (expected leave set).
        local ExpectedLinks = {
            [true] = {
                a = {"a -> bc", "ac -> bd", "e"},
                b = {"b -> d", "e"},
                c = {"ac -> bd"},
            },
            [false] = {
                b = {"a -> bc", "ac -> bd"},
                c = {"a -> bc"},
                d = {"b -> d", "ac -> bd"},
            },
        }
        local linkCount = 0
        for linkIndex,leaves in pairs(prepGraph.links) do
            local expectedLeaves = newLeavesSet(nodes, ExpectedLinks[linkIndex.isFromRoot][linkIndex.symbol])
            assert.is_not_nil(expectedLeaves)
            assert.are.same(leaves, expectedLeaves)
            linkCount = linkCount + 1
        end
        assert.are.equals(linkCount, 6)
    end)
end)

-- Creates a set of PrepNodeIndex from an array of edge indices.
--
-- Args:
-- * nodes[edgeIndex]: Map of PrepNode, indexed by the edge's string.
-- * edgeIndices: Array of edge's string indices.
--
-- Returns: A set of PrepNodeIndex correspondng to edgeIndices.
--
newLeavesSet = function(nodes, edgeIndices)
    local result = {}
    for _,edgeIndex in pairs(edgeIndices) do
        result[nodes[edgeIndex].index] = true
    end
    return result
end

-- Creates a new DirectedHypergraph with some hardcoded values.
--
-- Returns: The new DirectedHypergraph object.
--
newSampleGraph = function()
    local result = DirectedHypergraph.new()

    local Edges = {
        {
            index = "a -> bc",
            inbound = { a = true},
            outbound = { b = true, c = true},
        },{
            index = "ac -> bd",
            inbound = { a = true, c = true},
            outbound = { b = true, d = true},
        },{
            index = "b -> d",
            inbound = {b = true},
            outbound = {d = true},
        },{
            index = "ab -> e",
            inbound = {a = true, b = true},
            outbound = {e = true},
        }
    }
    for _,edge in pairs(Edges) do
        result:addEdge(DirectedHypergraphEdge.new(edge))
    end

    return result
end
