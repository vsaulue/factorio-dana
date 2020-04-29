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

local DirectedGraph = require("lua/graph/DirectedGraph")

local checkGraph

describe("DirectedGraph", function()
    local graph

    before_each(function()
        graph = DirectedGraph.new()
    end)

    after_each(function()
        graph = nil
    end)

    it("constructor", function()
        local count = 0
        for _ in pairs(graph.vertices) do
            count = count + 1
        end
        assert.are.equals(count, 0)
    end)

    describe(":addVertexIndex()", function()
        it("-- valid", function()
            graph:addVertexIndex("newId")
            assert.is_not_nil(graph.vertices["newId"])
            checkGraph(graph)
        end)

        it("-- duplicate id (error)", function()
            graph:addVertexIndex("newId")
            assert.has_error(function()
                graph:addVertexIndex("newId")
            end)
        end)
    end)

    describe(":addEdge()", function()
        before_each(function()
            graph:addVertexIndex("id1")
            graph:addVertexIndex("id2")
            graph:addVertexIndex("id3")
        end)

        it("-- valid", function()
            graph:addEdge("id1","id3",1)
            assert.is_not_nil(graph.vertices["id1"].outbound["id3"])
            checkGraph(graph)
        end)

        it("-- invalid inbound", function()
            assert.has_error(function()
                graph:addEdge("id0","id3",1)
            end)
        end)

        it("-- invalid outbound", function()
            assert.has_error(function()
                graph:addEdge("id2","id0",1)
            end)
        end)

        it("-- duplicate (error)", function()
            graph:addEdge("id2","id3",4)
            assert.has_error(function()
                graph:addEdge("id2","id3",1)
            end)
        end)
    end)

    describe(":removeEdge()", function()
        before_each(function()
            graph:addVertexIndex("id1")
            graph:addVertexIndex("id2")
            graph:addVertexIndex("id3")
            graph:addEdge("id1", "id2", 1)
            graph:addEdge("id1", "id3", 2)
            graph:addEdge("id2", "id3", 3)
        end)

        it("-- valid", function()
            local edge = graph.vertices["id1"].outbound["id2"]
            graph:removeEdge(edge)
            checkGraph(graph)
            assert.has_error(function()
                local _ = graph.vertices["id1"].outbound["id2"]
            end)
        end)

        it("-- invalid (edge not present)", function()
            local edge = {
                inbound = "id1",
                outbount = "id3",
                weight = 2,
            }
            assert.has_error(function()
                graph:removeEdge(edge)
            end)
        end)
    end)
end)

-- Asserts that a DirectedGraph object is in a consistent state.
--
-- Args:
-- * graph: DirectedGraph object to check.
--
checkGraph = function(graph)
    for vIndex1,vertex1 in pairs(graph.vertices) do
        assert.are.equals(vIndex1, vertex1.index)
        for vIndex2, edge in pairs(vertex1.outbound) do
            assert.are.equals(edge.inbound, vIndex1)
            assert.are.equals(edge.outbound, vIndex2)
            local vertex2 = graph.vertices[vIndex2]
            assert.are.equals(vertex2.inbound[vIndex1], edge)
        end
    end
end
