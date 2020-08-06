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

local PrepGraph = require("lua/layouts/preprocess/PrepGraph")
local TestUtils = require("lua/layouts/preprocess/tests/PrepTestsUtility")

local SampleLinkIndices
local SampleNodeIndices
local setSampleGraph

describe("PrepGraph", function()
    local graph = PrepGraph.new()

    before_each(function()
        graph = PrepGraph.new()
    end)

    after_each(function()
        graph = nil
    end)

    describe(":newNode()", function()
        it("-- valid", function()
            setSampleGraph(graph)
            local node = graph:newNode(TestUtils.makeNodeIndex("hyperEdge", "foobar"))
            assert.are.equals(graph.nodes[node.index], node)
            TestUtils.checkConsistency(graph)
        end)

        it("-- duplicate index", function()
            setSampleGraph(graph)
            assert.error(function()
                graph:newNode(SampleNodeIndices.b)
            end)
        end)
    end)

    describe(":addLink()", function()
        it("-- from root", function()
            local NI = SampleNodeIndices
            setSampleGraph(graph)
            local linkIndex = TestUtils.makeLinkIndex(true, NI.b)
            local leaves = {[NI["ab -> c"]] = true, [NI.a] = true}

            graph:addLink(linkIndex, leaves)

            assert.are.equals(graph.links[linkIndex], leaves)
            assert.is_true(graph.nodes[NI.b].outboundSlots[linkIndex])
            assert.is_true(graph.nodes[NI.a].inboundSlots[linkIndex])
            assert.is_true(graph.nodes[NI["ab -> c"]].inboundSlots[linkIndex])

            TestUtils.checkConsistency(graph)
        end)

        it("-- to root", function()
            local NI = SampleNodeIndices
            setSampleGraph(graph)
            local linkIndex = TestUtils.makeLinkIndex(false, NI.c)
            local leaves = {[NI["ab -> c"]] = true, [NI.b] = true}

            graph:addLink(linkIndex, leaves)

            assert.are.equals(graph.links[linkIndex], leaves)
            assert.is_true(graph.nodes[NI.c].inboundSlots[linkIndex])
            assert.is_true(graph.nodes[NI.b].outboundSlots[linkIndex])
            assert.is_true(graph.nodes[NI["ab -> c"]].outboundSlots[linkIndex])

            TestUtils.checkConsistency(graph)
        end)

        it("-- invalid (duplicate index)", function()
            local NI = SampleNodeIndices
            local LI = SampleLinkIndices
            setSampleGraph(graph)

            assert.error(function()
                graph:addLink(LI.aOut, { [NI.a] = true })
            end)
        end)
    end)

    it(":newSubgraph()", function()
        local LI = SampleLinkIndices
        local NI = SampleNodeIndices
        setSampleGraph(graph)
        local nodeIndices = {NI.a, NI.b, NI["ab -> c"], NI["b -> ac"]}
        local subgraph = graph:newSubgraph(TestUtils.arrayToSet(nodeIndices))

        for _,nodeIndex in pairs(nodeIndices) do
            assert.is_not_nil(subgraph.nodes[nodeIndex])
        end

        local checkLink = function(linkIndex, leafArray)
            assert.are.same(subgraph.links[linkIndex], TestUtils.arrayToSet(leafArray))
        end

        checkLink(LI.aOut, { NI["ab -> c"] })
        checkLink(LI.bOut, { NI["b -> ac"], NI["ab -> c"] })
        checkLink(LI.aIn,  { NI["b -> ac"]})
        assert.is_nil(rawget(subgraph.links, LI.cIn))

        TestUtils.checkConsistency(subgraph)
    end)
end)

-- Map[nodeId]: PrepNodeIndex. Node indices used by setSampleGraph.
SampleNodeIndices = {
    a = TestUtils.makeNodeIndex("hyperVertex", "a"),
    b = TestUtils.makeNodeIndex("hyperVertex", "b"),
    c = TestUtils.makeNodeIndex("hyperVertex", "c"),
    ["ab -> c"] = TestUtils.makeNodeIndex("hyperEdge", "ab -> c"),
    ["b -> ac"] = TestUtils.makeNodeIndex("hyperEdge", "b -> ac"),
}

-- Map[linkId]: PrepLinkIndex. Link indices used by setSampleGraph.
SampleLinkIndices = {
    aOut = TestUtils.makeLinkIndex(true, SampleNodeIndices.a),
    bOut = TestUtils.makeLinkIndex(true, SampleNodeIndices.b),
    aIn = TestUtils.makeLinkIndex(false, SampleNodeIndices.a),
    cIn = TestUtils.makeLinkIndex(false, SampleNodeIndices.c),
}

-- Fills a PrepGraph with some hardcoded values.
--
-- Args:
-- * graph: PrepGraph object to fill.
setSampleGraph = function(graph)
    local links = graph.links
    local nodes = graph.nodes
    local LI = SampleLinkIndices
    local NI = SampleNodeIndices

    links[LI.aOut] = { [NI["ab -> c"]] = true}
    links[LI.bOut] = { [NI["b -> ac"]] = true, [NI["ab -> c"]] = true}
    links[LI.aIn] = { [NI["b -> ac"]] = true}
    links[LI.cIn] = { [NI["ab -> c"]] = true, [NI["b -> ac"]] = true}

    nodes[NI.a] = {
        index = NI.a,
        inboundSlots = { [LI.aIn] = true },
        outboundSlots = { [LI.aOut] = true },
    }
    nodes[NI.b] = {
        index = NI.b,
        inboundSlots = {},
        outboundSlots = { [LI.bOut] = true },
    }
    nodes[NI.c] = {
        index = NI.c,
        inboundSlots = { [LI.cIn] = true },
        outboundSlots = {},
    }
    nodes[NI["ab -> c"]] = {
        index = NI["ab -> c"],
        inboundSlots = { [LI.aOut] = true, [LI.bOut] = true},
        outboundSlots = { [LI.cIn] = true},
    }
    nodes[NI["b -> ac"]] = {
        index = NI["b -> ac"],
        inboundSlots = { [LI.bOut] = true},
        outboundSlots = { [LI.aIn] = true, [LI.cIn] = true},
    }
    TestUtils.checkConsistency(graph)
end
