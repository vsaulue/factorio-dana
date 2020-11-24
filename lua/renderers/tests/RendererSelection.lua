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

local RendererSelection = require("lua/renderers/RendererSelection")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TreeLinkNode = require("lua/layouts/TreeLinkNode")

describe("RendererSelection", function()
    local object
    before_each(function()
        object = RendererSelection.new()
    end)

    it(".new()", function()
        assert.are.same(object, {
            links = {},
            nodes = {
                hyperEdge = {},
                hyperOneToOne = {},
                hyperVertex = {},
            },
        })
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = object,
            metatableSetter = RendererSelection.setmetatable,
        }
    end)

    it(":makeAggregatedLinkSelection()", function()
        local node1 = TreeLinkNode.new{linkIndex = "linkIndex1"}
        local node1a = TreeLinkNode.new()
        local node1b = TreeLinkNode.new{edgeIndex = "edgeIndex1b"}
        node1:addChild(node1a)
        node1:addChild(node1b)
        local node1aa = TreeLinkNode.new{edgeIndex = "edgeIndex1aa"}
        local node1ab = TreeLinkNode.new{edgeIndex = "edgeIndex1ab"}
        node1a:addChild(node1aa)
        node1a:addChild(node1ab)

        local node2 = TreeLinkNode.new{linkIndex = "linkIndex2"}
        local node2a = TreeLinkNode.new{edgeIndex = "edgeIndex2a"}
        node2:addChild(node2a)

        object.links = {[node1a] = true, [node2] = true}
        local result = object:makeAggregatedLinkSelection()
        assert.are.same(result, {
            linkIndex1 = {edgeIndex1aa = true, edgeIndex1ab = true},
            linkIndex2 = {edgeIndex2a = true},
        })
    end)
end)
