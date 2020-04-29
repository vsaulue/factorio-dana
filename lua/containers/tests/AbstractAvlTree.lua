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

local AbstractAvlTree = require("lua/containers/AbstractAvlTree")
local Stack = require("lua/containers/Stack")

-- Forward declarations & aliases
local checkFindNode
local checkFindNodeGreater
local checkNode
local checkStack
local checkTree
local getKeys
local getKeysImpl
local NoChild = AbstractAvlTree.NoChild
local setSampleTree

describe("AbstractAvlTree", function()
    local tree

    before_each(function()
        tree = AbstractAvlTree.new{
            newNode = function()
                return {}
            end,
        }
    end)

    after_each(function()
        checkTree(tree)
        tree = nil
    end)

    it("constructor", function()
        assert.are.equals(tree.root, NoChild)
    end)

    it(":findNode()", function()
        setSampleTree(tree)
        local keys = getKeys(tree)
        for _,key in ipairs(keys) do
            checkFindNode(tree, key)
        end
        assert.is_nil(tree:findNode(21))
    end)

    describe(":getNodeGreater()", function()
        it("-- strict", function()
            setSampleTree(tree)
            local keys = getKeys(tree)
            local count = #keys
            for i=1,count-1 do
                checkFindNodeGreater(tree, keys[i], true, keys[i+1])
                local weightedAvg = (9*keys[i] + keys[i+1]) / 10
                checkFindNodeGreater(tree, weightedAvg, true, keys[i+1])
            end
            checkFindNodeGreater(tree, keys[count], true, nil)
            checkFindNodeGreater(tree, keys[count]+5, true, nil)
        end)

        it("-- greaterOrEqual", function()
            setSampleTree(tree)
            local keys = getKeys(tree)
            local count = #keys
            for i=1,count do
                checkFindNodeGreater(tree, keys[i], false, keys[i])
                local weightedAvg = (9*keys[i] + (keys[i+1] or math.huge)) / 10
                checkFindNodeGreater(tree, weightedAvg, false, keys[i+1])
            end
            checkFindNodeGreater(tree, keys[count], false, keys[count])
            checkFindNodeGreater(tree, keys[count]+5, false, nil)
        end)
    end)

    describe(":getOrCreateNode()", function()
        it("-- simple left rotation", function()
            setSampleTree(tree)
            local key = 13
            local node = tree:getOrCreateNode(key)
            assert.are.equals(node, checkFindNode(tree, key))
        end)

        it("-- simple right rotation", function()
            setSampleTree(tree)
            local key = 15
            local node = tree:getOrCreateNode(key)
            assert.are.equals(node, checkFindNode(tree, key))
        end)

        it("-- double right rotation", function()
            setSampleTree(tree)
            local key = -4
            local node = tree:getOrCreateNode(key)
            assert.are.equals(node, checkFindNode(tree, key))
        end)

        it("-- double left rotation", function()
            setSampleTree(tree)
            local key = 13
            local node = tree:getOrCreateNode(key)
            assert.are.equals(node, checkFindNode(tree, key))
        end)

        it("-- duplicate key", function()
            local values = {1,-8,15,13,85,159,-14,7,35,20,21,22,23,24,25,26,74,-555,-4,-10,-11,-12,-13}
            local nodes = {}

            for _,key in ipairs(values) do
                nodes[key] = tree:getOrCreateNode(key)
            end
            checkTree(tree)

            for i=#values,1,-1 do
                local key = values[i]
                local node2 = tree:getOrCreateNode(key)
                assert.are.equals(node2, nodes[key])
            end
        end)
    end)

    describe(":remove()", function()
        it("-- simple left unbalance", function()
            setSampleTree(tree)
            local keys = getKeys(tree)
            local deletedKey = 6
            tree:removeAt(tree:findNode(deletedKey))

            for _,key in pairs(keys) do
                if key ~= deletedKey then
                    checkFindNode(tree, key)
                else
                    assert.is_nil(tree:findNode(key))
                end
            end
        end)

        it("-- simple right unbalance", function()
            setSampleTree(tree)
            local keys = getKeys(tree)
            local deletedKey = 11
            tree:removeAt(tree:findNode(deletedKey))

            for _,key in pairs(keys) do
                if key ~= deletedKey then
                    checkFindNode(tree, key)
                else
                    assert.is_nil(tree:findNode(key))
                end
            end
        end)

        it("-- complex left unbalance", function()
            setSampleTree(tree)
            local keys = getKeys(tree)
            local deletedKey = 20
            tree:removeAt(tree:findNode(deletedKey))

            for _,key in pairs(keys) do
                if key ~= deletedKey then
                    checkFindNode(tree, key)
                else
                    assert.is_nil(tree:findNode(key))
                end
            end
        end)

        it("-- complex right unbalance & root", function()
            setSampleTree(tree)
            local keys = getKeys(tree)
            local deletedKey = 10
            tree:removeAt(tree:findNode(deletedKey))

            for _,key in pairs(keys) do
                if key ~= deletedKey then
                    checkFindNode(tree, key)
                else
                    assert.is_nil(tree:findNode(key))
                end
            end
        end)
    end)
end)

-- Runs the findNode() method and checks its return values.
--
-- Args:
-- * tree: AbstractAvlTree object.
-- * key: Key to look for.
--
-- Returns: The found node.
--
checkFindNode = function(tree, key)
    local node,stack = tree:findNode(key)
    checkStack(tree, stack, node)
    assert.is_not_nil(node)
    assert.are.equals(node.key, key)
    return node
end

-- Runs the findNode() method and checks its return values.
--
-- Args:
-- * tree: AbstractAvlTree object.
-- * key: Key to look for.
--
checkFindNodeGreater = function(tree, key, isStrict, expectedKey)
    local node = tree:findNodeGreater(key, isStrict)
    if expectedKey then
        if isStrict then
            assert.is_true(key < node.key)
        else
            assert.is_true(key <= node.key)
        end
        assert.are.equals(node.key, expectedKey)
    else
        assert.is_nil(node)
    end
end

-- Asserts that a node/subtree is a valid AVL tree.
--
-- Args:
-- * node: Node to test.
--
checkNode = function(node)
    local height = 0
    if node ~= NoChild then
        local lowHeight = checkNode(node.lowerNode)
        local highHeight = checkNode(node.greaterNode)
        assert.are.equals(highHeight - lowHeight, node.balance)
        assert.is_true(-1 <= node.balance and node.balance <= 1)
        height = 1 + math.max(highHeight, lowHeight)
        if lowHeight > 1 then
            assert.is_true(node.lowerNode.key < node.key)
        end
        if highHeight > 1 then
            assert.is_true(node.key < node.greaterNode.key)
        end
    end
    return height
end

-- Asserts that a navigation stack is correct.
--
-- Args:
-- * tree: AbstractAvlTree containing the node.
-- * stack: Navigation stack from the root to the node.
-- * node: Expected navigation node at the end of the stack.
--
checkStack = function(tree, stack, node)
    local topIndex = stack.topIndex
    assert.are.equals(topIndex % 2, 0, "AbstractAvlTree: corrupted stack (invalid number of elements).")
    local current = tree.root
    local index = 1
    while index <= stack.topIndex do
        current = stack[index][stack[index+1]]
        index = index + 2
    end
    assert(current == node)
end

-- Asserts that a tree is a valid AVL tree.
--
-- Args:
-- * tree: AbstractAvlTree to test.
--
checkTree = function(tree)
    checkNode(tree.root)
end

-- Gets all the keys in a given tree, sorted.
--
-- Args:
-- * tree: AbstractAvlTree to parse.
--
-- Returns: A sorted table containing all the keys in the tree.
--
getKeys = function(tree)
    local result = {}
    getKeysImpl(tree.root, result)

    -- If the tree is a valid rearch tree, the array should already be sorted.
    -- But if we could assume that the tree is correct, I wouldn't be writing this file :-)
    table.sort(result)

    return result
end

-- Appends all the keys of a subtree to the given array.
--
-- Args:
-- * node: Subtree to parse.
-- * array: Array to fill.
--
getKeysImpl = function(node, array)
    if node ~= NoChild then
        getKeysImpl(node.lowerNode, array)
        table.insert(array, node.key)
        getKeysImpl(node.greaterNode, array)
    end
end

-- Replace the given tree with an hardcoded one.
--
-- Args:
-- * tree: Tree to edit.
--
setSampleTree = function(tree)
    tree.root = {
        balance = 1,
        key = 10,
        greaterNode = {
            balance = -1,
            key = 20,
            greaterNode = {
                balance = 0,
                key = 25,
                greaterNode = NoChild,
                lowerNode = NoChild,
            },
            lowerNode = {
                balance = 1,
                key = 11,
                greaterNode = {
                    balance = 0,
                    key = 15,
                    greaterNode = NoChild,
                    lowerNode = NoChild,
                },
                lowerNode = NoChild,
            }
        },
        lowerNode = {
            balance = -1,
            key = 6,
            greaterNode = NoChild,
            lowerNode = {
                balance = 0,
                key = -5,
                greaterNode = NoChild,
                lowerNode = NoChild,
            },
        },
    }
    checkTree(tree) -- makes sure the hardcoded tree is valid.
end
