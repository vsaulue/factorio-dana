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
local ReversibleArray = require("lua/containers/ReversibleArray")
local TopologicalOrderGenerator = require("lua/graph/algorithms/TopologicalOrderGenerator")

local checkCandidate

describe("TopologicalOrderGenerator", function()
    local inputGraph

    before_each(function()
        inputGraph = DirectedGraph.new()
    end)

    after_each(function()
        inputGraph = nil
    end)

    it("acyclic graph", function()
        inputGraph:addVertexIndex("id_1a")
        inputGraph:addVertexIndex("id_1b")
        inputGraph:addVertexIndex("id_1c")
        inputGraph:addVertexIndex("id_2a")
        inputGraph:addVertexIndex("id_2b")
        inputGraph:addVertexIndex("id_3")
        inputGraph:addEdge("id_1a", "id_2a", 1)
        inputGraph:addEdge("id_1b", "id_2a", 1)
        inputGraph:addEdge("id_1c", "id_2b", 1)
        inputGraph:addEdge("id_2a", "id_3", 1)
        inputGraph:addEdge("id_2b", "id_3", 1)

        local candidates = ReversibleArray.new()
        local generator = TopologicalOrderGenerator.new{
            candidateCallback = function(id)
                candidates:pushBack(id)
            end,
            graph = inputGraph,
        }
        checkCandidate(candidates, "id_1a")
        checkCandidate(candidates, "id_1b")
        checkCandidate(candidates, "id_1c")
        assert.are.equals(candidates.count, 3)

        generator:select("id_1c")
        checkCandidate(candidates, "id_2b")
        assert.are.equals(candidates.count, 4)

        generator:select("id_1b")
        assert.are.equals(candidates.count, 4)

        generator:select("id_2b")
        assert.are.equals(candidates.count, 4)

        generator:select("id_1a")
        checkCandidate(candidates, "id_2a")
        assert.are.equals(candidates.count, 5)

        generator:select("id_2a")
        checkCandidate(candidates, "id_3")
        assert.are.equals(candidates.count, 6)
    end)

    it("graph with cycles", function()
        inputGraph:addVertexIndex("source")
        inputGraph:addVertexIndex("id_1")
        inputGraph:addVertexIndex("id_2")
        inputGraph:addEdge("source", "id_1", 1)
        inputGraph:addEdge("id_1", "id_2", 1)
        inputGraph:addEdge("id_2", "id_1", 1)

        local candidates = ReversibleArray.new()
        local generator = TopologicalOrderGenerator.new{
            candidateCallback = function(id)
                candidates:pushBack(id)
            end,
            graph = inputGraph,
        }
        checkCandidate(candidates, "source")
        assert.are.equals(candidates.count, 1)

        generator:select("source")
        assert.are.equals(candidates.count, 1)
    end)

    it("graph with only cycles", function()
        inputGraph:addVertexIndex("id_1")
        inputGraph:addVertexIndex("id_2")
        inputGraph:addEdge("id_1", "id_2", 1)
        inputGraph:addEdge("id_2", "id_1", 1)

        local candidates = ReversibleArray.new()
        local generator = TopologicalOrderGenerator.new{
            candidateCallback = function(id)
                candidates:pushBack(id)
            end,
            graph = inputGraph,
        }
        assert.are.equals(candidates.count, 0)
    end)
end)

-- Checks if a value is in the given ReversibleArray object.
--
-- Args:
-- * reversibleArray: ReversibleArray object.
-- * id: Value to look for.
--
checkCandidate = function(reversibleArray, id)
    assert.is_not_nil(rawget(reversibleArray.reverse, id))
end
