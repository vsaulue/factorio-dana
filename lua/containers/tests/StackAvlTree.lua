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

local Stack = require("lua/containers/Stack")
local StackAvlTree = require("lua/containers/StackAvlTree")

local NoChild = StackAvlTree.NoChild

local function makeSampleTreeImpl(nodeInfo)
    local newNode = NoChild
    local total = 0
    if nodeInfo then
        newNode = Stack.new()

        for _,v in ipairs(nodeInfo.values) do
            newNode:push(v)
        end

        local lowerNode,lowerTotal = makeSampleTreeImpl(nodeInfo.lowerNode)
        local greaterNode,greaterTotal = makeSampleTreeImpl(nodeInfo.greaterNode)

        newNode.key = nodeInfo.key
        newNode.balance = nodeInfo.balance
        newNode.lowerNode = lowerNode
        newNode.greaterNode = greaterNode

        total = newNode.topIndex + lowerTotal + greaterTotal
    end

    return newNode,total
end

local function makeSampleTree(tree, info)
    tree.root,tree.count = makeSampleTreeImpl(info)
end

local function setSampleTree(tree)
    makeSampleTree(tree,{
        key = 10,
        balance = 0,
        values = {"10a"},
        greaterNode = {
            key = 20,
            balance = 0,
            values = {"20a", "20b"},
        },
        lowerNode = {
            key = 0,
            balance = 0,
            values = {"0a", "0b"},
        },
    })
end

describe("StackAvlTree", function()
    local tree

    before_each(function()
        tree = StackAvlTree.new()
    end)

    after_each(function()
        tree = nil
    end)

    it("constructor", function()
        assert.are.equals(tree.count, 0)
        assert.are.equals(tree.root, NoChild)
    end)

    describe(":push()", function()
        local prevCount

        before_each(function()
            setSampleTree(tree)
            prevCount = tree.count
        end)

        after_each(function()
            prevCount = nil
        end)

        it("-- Non-existing node", function()
            tree:push(25, "25a")

            assert.are.equals(tree.count, prevCount + 1)
            local node = tree.root.greaterNode.greaterNode
            assert.are.equals(node.topIndex, 1)
            assert.are.equals(node[1], "25a")
        end)

        it("-- Existing node", function()
            tree:push(10, "10b")

            assert.are.equals(tree.count, prevCount + 1)
            local node = tree.root
            assert.are.equals(node.topIndex, 2)
            assert.are.equals(node[1], "10a")
            assert.are.equals(node[2], "10b")
        end)
    end)

    describe(":popGreater()", function()
        local prevCount

        before_each(function()
            setSampleTree(tree)
            prevCount = tree.count
        end)

        after_each(function()
            prevCount = nil
        end)

        describe("-- out of bounds", function()
            it("(strict)", function()
                setSampleTree(tree)
                local key,value = tree:popGreater(25, true)
                assert.is_nil(key)
                assert.is_nil(value)
                assert.are.equals(tree.count, prevCount)
            end)

            it("(strict or equal)", function()
                setSampleTree(tree)
                local key,value = tree:popGreater(25.001, false)
                assert.is_nil(key)
                assert.is_nil(value)
                assert.are.equals(tree.count, prevCount)
            end)
        end)

        describe("-- node with 1 item", function()
            it("(strict)", function()
                setSampleTree(tree)
                local key,value = tree:popGreater(0.001, true)
                assert.are.equals(key, 10)
                assert.are.equals(value, "10a")
                assert.are_not.equals(tree.root.key, 10)
                assert.are.equals(tree.count, prevCount - 1)
            end)

            it("(strict or equal)", function()
                setSampleTree(tree)
                local key,value = tree:popGreater(10, false)
                assert.are.equals(key, 10)
                assert.are.equals(value, "10a")
                assert.are_not.equals(tree.root.key, 10)
                assert.are.equals(tree.count, prevCount - 1)
            end)
        end)

        describe("-- node with 2+ items", function()
            it("(strict)", function()
                setSampleTree(tree)
                local key,value = tree:popGreater(-0.001, true)
                assert.are.equals(key, 0)
                assert.are.equals(value, "0b")
                assert.are.equals(tree.root.lowerNode.key, 0)
                assert.are.equals(tree.root.lowerNode[1], "0a")
                assert.are.equals(tree.root.lowerNode.topIndex, 1)
                assert.are.equals(tree.count, prevCount - 1)
            end)

            it("(strict or equal)", function()
                setSampleTree(tree)
                local key,value = tree:popGreater(0, false)
                assert.are.equals(key, 0)
                assert.are.equals(value, "0b")
                assert.are.equals(tree.root.lowerNode.key, 0)
                assert.are.equals(tree.root.lowerNode[1], "0a")
                assert.are.equals(tree.root.lowerNode.topIndex, 1)
                assert.are.equals(tree.count, prevCount - 1)
            end)
        end)
    end)
end)