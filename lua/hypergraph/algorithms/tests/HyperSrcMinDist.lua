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
local HyperSrcMinDist = require("lua/hypergraph/algorithms/HyperSrcMinDist")

local assertMapsAreEquals
local setSampleGraph

describe("HyperSrcMinDist", function()
    local graph

    before_each(function()
        graph = DirectedHypergraph.new()
    end)

    after_each(function()
        graph = nil
    end)

    it(".fromSource()", function()
        setSampleGraph(graph)

        local result = HyperSrcMinDist.fromSource(graph, {a = true, c = true})

        assertMapsAreEquals(result, {
            a = 0,
            c = 0,
            d = 1,
            z = 1,
            f1 = 1,
            e = 2,
            f2 = 2,
            f3 = 3,
            f4 = 4,
        })
    end)
end)

-- Tests the keys & values of a map.
--
-- Args:
-- * map: Key/value table to test.
-- * expected: map containing the expected keys & values.
--
assertMapsAreEquals = function(map, expected)
    for key,value in pairs(expected) do
        assert.are.equals(map[key], value)
    end

    for key in pairs(map) do
        assert.is_not_nil(expected[key])
    end
end

-- Fills a DirectedHypergraph object with hardcoded values.
--
-- Args:
-- * graph: DirectedHypergraph object to fill.
--
setSampleGraph = function(graph)
    graph:addEdge(DirectedHypergraphEdge.new{
        index = "-> z",
        inbound = {},
        outbound = { z = true},
    })

    graph:addEdge(DirectedHypergraphEdge.new{
        index = "ab -> c",
        inbound = { a = true, b = true},
        outbound = { c = true},
    })
    graph:addEdge(DirectedHypergraphEdge.new{
        index = "a -> d",
        inbound = { a = true},
        outbound = { d = true},
    })
    graph:addEdge(DirectedHypergraphEdge.new{
        index = "d -> ef1",
        inbound = { d = true},
        outbound = { e = true, f1 = true},
    })
    graph:addEdge(DirectedHypergraphEdge.new{
        index = "c -> f1",
        inbound = { c = true},
        outbound = { f1 = true},
    })

    -- f1 -> f2 -> f3 -> f4
    for i=1,3 do
        local srcIndex = "f" .. i
        local dstIndex = "f" .. i+1
        graph:addEdge(DirectedHypergraphEdge.new{
            index = srcIndex .. " -> " .. dstIndex,
            inbound = { [srcIndex] = true},
            outbound = { [dstIndex] = true},
        })
    end
end
