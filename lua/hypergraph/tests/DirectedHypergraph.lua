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
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("DirectedHypergraph", function()
    local graph
    before_each(function()
        graph = DirectedHypergraph.new()
    end)

    it(".new()", function()
        assert.are.same(graph, {
            edges = {},
            vertices = {},
        })
    end)

    it(".setmetatable()", function()
        graph:addEdge(DirectedHypergraphEdge.new{
            index = "e1",
            inbound = {v1 = true},
            outbound = {v2 = true},
        })
        SaveLoadTester.run{
            objects = graph,
            metatableSetter = DirectedHypergraph.setmetatable,
        }
    end)

    it(":addEdge()", function()
        graph:addEdge(DirectedHypergraphEdge.new{
            index = "e1",
            inbound = {v1 = true, v2 = true},
            outbound = {v3 = true},
        })
        graph:addEdge(DirectedHypergraphEdge.new{
            index = "e2",
            inbound = {v3 = true, v2 = true},
            outbound = {v1 = true},
        })
        assert.are.same(graph, {
            edges = {
                e1 = graph.edges.e1,
                e2 = graph.edges.e2,
            },
            vertices = {
                v1 = {
                    index = "v1",
                    inbound = {
                        e2 = graph.edges.e2,
                    },
                    outbound = {
                        e1 = graph.edges.e1,
                    },
                },
                v2 = {
                    index = "v2",
                    inbound = {},
                    outbound = {
                        e1 = graph.edges.e1,
                        e2 = graph.edges.e2,
                    },
                },
                v3 = {
                    index = "v3",
                    inbound = {
                        e1 = graph.edges.e1,
                    },
                    outbound = {
                        e2 = graph.edges.e2,
                    },
                },
            },
        })

        assert.error(function()
            graph:addEdge(DirectedHypergraphEdge.new{
                index = "e1",
                inbound = {},
                outbound = {},
            })
        end)
    end)

    it(":addVertexIndex()", function()
        graph:addVertexIndex("v1")
        assert.are.same(graph.vertices, {
            v1 = {
                index = "v1",
                inbound = {},
                outbound = {},
            }
        })
        local vertex = graph.vertices.v1

        graph:addVertexIndex("v1")
        assert.are.equals(vertex, graph.vertices.v1)
    end)

    it(":removeEdgeIndex()", function()
        graph:addEdge(DirectedHypergraphEdge.new{
            index = "e1",
            inbound = {v1 = true, v2 = true},
            outbound = {v3 = true},
        })
        graph:addEdge(DirectedHypergraphEdge.new{
            index = "e2",
            inbound = {v3 = true, v2 = true},
            outbound = {v1 = true},
        })

        graph:removeEdgeIndex("e1")

        local expectedGraph = {
            edges = {
                e2 = graph.edges.e2,
            },
            vertices = {
                v1 = {
                    index = "v1",
                    inbound = {
                        e2 = graph.edges.e2,
                    },
                    outbound = {},
                },
                v2 = {
                    index = "v2",
                    inbound = {},
                    outbound = {
                        e2 = graph.edges.e2,
                    },
                },
                v3 = {
                    index = "v3",
                    inbound = {},
                    outbound = {
                        e2 = graph.edges.e2,
                    },
                },
            },
        }
        assert.are.same(graph, expectedGraph)
    end)
end)
