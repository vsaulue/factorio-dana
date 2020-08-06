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
local PrepGraph = require("lua/layouts/preprocess/PrepGraph")
local PrepSCC = require("lua/layouts/preprocess/algorithms/PrepSCC")
local TestUtils = require("lua/layouts/preprocess/tests/PrepTestsUtility")

describe("PrepSCC", function()
    it(".run()", function()
        -- Sample graph
        local graph,nodes = TestUtils.makeSampleGraph{
            vertexIndices = {"a","b1","b2","c1","c2","c3","d","e"},
            edges = {
                {
                    id = "a -> b1c1",
                    inbound = {"a"},
                    outbound = {"b1","c1"},
                },{
                    id = "ab2 -> b1",
                    inbound = {"a","b2"},
                    outbound = {"b1"},
                },{
                    id = "b1b2 -> b2d",
                    inbound = {"b1","b2"},
                    outbound = {"b2","d"},
                },{
                    id = "c2c3 -> c1e",
                    inbound = {"c2","c3"},
                    outbound = {"c1","e"},
                },{
                    id = "c1 -> c2",
                    inbound = {"c1"},
                    outbound = {"c2"},
                },{
                    id = "c2 -> c3",
                    inbound = {"c2"},
                    outbound = {"c3"},
                },{
                    id = "c1 -> e",
                    inbound = {"c1"},
                    outbound = {"e"},
                }
            },
        }

        -- Run the SCC algorithm
        local scc = PrepSCC.run(graph)

        -- Checking
        local nodeIdToSCC = {}
        local sccToRank = {}
        local count = 0
        for i=1,scc.components.count do
            local component = scc.components[i]
            for nodeIndex in pairs(component) do
                assert.is_nil(nodeIdToSCC[nodeIndex.index])
                nodeIdToSCC[nodeIndex.index] = component
                count = count + 1
            end
            sccToRank[component] = i
        end
        assert.are.equals(count, 15)

        local ExpectedSCCs = {
            {"a"},
            {"a -> b1c1"},
            {"b1","b2","ab2 -> b1","b1b2 -> b2d"},
            {"c1","c2","c3","c2c3 -> c1e","c1 -> c2","c2 -> c3"},
            {"c1 -> e"},
            {"d"},
            {"e"},
        }
        assert.are.equals(scc.components.count, #ExpectedSCCs)
        for _,expectedComponent in pairs(ExpectedSCCs) do
            local firstNodeId = expectedComponent[1]
            local component = nodeIdToSCC[firstNodeId]
            for i=2,#expectedComponent do
                assert.are.equals(nodeIdToSCC[expectedComponent[i]], component)
            end
        end

        local assertOrder = function(higherId, lowerId)
            local lowRank = sccToRank[nodeIdToSCC[lowerId]]
            local highRank = sccToRank[nodeIdToSCC[higherId]]
            assert.is_true(lowRank < highRank)
        end
        assertOrder("a","a -> b1c1")
        assertOrder("a -> b1c1", "b1")
        assertOrder("a -> b1c1", "c1")
        assertOrder("b1", "d")
        assertOrder("c1", "c1 -> e")
        assertOrder("c1 -> e", "e")
    end)
end)

return PrepSCC
