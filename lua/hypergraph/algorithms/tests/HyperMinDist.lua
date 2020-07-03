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
local HyperMinDist = require("lua/hypergraph/algorithms/HyperMinDist")

local assertMapsAreEquals
local setSampleGraph

describe("HyperMinDist", function()
    local graph

    before_each(function()
        graph = DirectedHypergraph.new()
    end)

    after_each(function()
        graph = nil
    end)

    describe(".fromSource", function()
        it("(*,*,false)", function()
            setSampleGraph(graph)
            local vertexDist,edgeDist = HyperMinDist.fromSource(graph, {a = true, c = true}, false)

            assertMapsAreEquals(vertexDist, {
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
            assertMapsAreEquals(edgeDist, {
                ["a -> d"] = 1,
                ["-> z"] = 1,
                ["c -> f1"] = 1,
                ["d -> ef1"] = 2,
                ["f1 -> f2"] = 2,
                ["f2 -> f3"] = 3,
                ["f3 -> f4"] = 4,
            })
        end)

        it("(*,*,false,2)", function()
            setSampleGraph(graph)
            local vertexDist,edgeDist = HyperMinDist.fromSource(graph, {a = true, e = true}, false, 2)

            assertMapsAreEquals(vertexDist, {
                a = 0,
                e = 0,
                d = 1,
                z = 1,
                f1 = 2,
            })
            assertMapsAreEquals(edgeDist, {
                ["a -> d"] = 1,
                ["-> z"] = 1,
                ["d -> ef1"] = 2,
            })
        end)

        it("(*,*,true)", function()
            setSampleGraph(graph)
            local vertexDist,edgeDist = HyperMinDist.fromSource(graph, {b = true}, true)

            assertMapsAreEquals(vertexDist, {
                b = 0,
                z = 1,
                c = 1,
                f1 = 2,
                f2 = 3,
                f3 = 4,
                f4 = 5,
            })
            assertMapsAreEquals(edgeDist, {
                ["ab -> c"] = 1,
                ["-> z"] = 1,
                ["c -> f1"] = 2,
                ["f1 -> f2"] = 3,
                ["f2 -> f3"] = 4,
                ["f3 -> f4"] = 5,
            })
        end)
    end)

    describe(".toDest", function()
        it("(*,*,false)", function()
            setSampleGraph(graph)
            local vertexDist,edgeDist = HyperMinDist.toDest(graph, {f3 = true, z = true}, false)

            assertMapsAreEquals(vertexDist, {
                f3 = 0,
                z = 0,
                f2 = 1,
                f1 = 2,
                c = 3,
                a = 4,
                b = 4,
            })
            assertMapsAreEquals(edgeDist, {
                ["f2 -> f3"] = 1,
                ["-> z"] = 1,
                ["f1 -> f2"] = 2,
                ["c -> f1"] = 3,
                ["ab -> c"] = 4,
            })
        end)

        it("(*,*,true)", function()
            setSampleGraph(graph)
            local vertexDist,edgeDist = HyperMinDist.toDest(graph, {f2 = true}, true)

            assertMapsAreEquals(vertexDist, {
                f2 = 0,
                f1 = 1,
                c = 2,
                d = 2,
                a = 3,
                b = 3,
            })
            assertMapsAreEquals(edgeDist, {
                ["f1 -> f2"] = 1,
                ["c -> f1"] = 2,
                ["d -> ef1"] = 2,
                ["ab -> c"] = 3,
                ["a -> d"] = 3,
            })
        end)

        it("(*,*,true,2)", function()
            setSampleGraph(graph)
            local vertexDist,edgeDist = HyperMinDist.toDest(graph, {f2 = true}, true, 2)

            assertMapsAreEquals(vertexDist, {
                f2 = 0,
                f1 = 1,
                c = 2,
                d = 2,
            })
            assertMapsAreEquals(edgeDist, {
                ["f1 -> f2"] = 1,
                ["c -> f1"] = 2,
                ["d -> ef1"] = 2,
            })
        end)
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
