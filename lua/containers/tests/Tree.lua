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

local Tree = require("lua/containers/Tree")

local hasParent
local makeTree

describe("Tree", function()
    local tree

    before_each(function()
        tree = Tree.new()
    end)

    after_each(function()
        tree = nil
    end)

    it("constructor", function()
        assert.is_not_nil(tree.children)
        assert.is_nil(rawget(tree, "parent"))
        assert.are.equals(tree.childCount, 0)
    end)

    it("setmetatable()", function()
        local tree2 = {
            children = {},
            childCount = 1,
        }
        local child = {
            parent = tree2,
            children = {},
            childCount = 0,
        }
        tree2.children[child] = true

        Tree.setmetatable(tree2)
        assert.is_not_nil(getmetatable(child))
        assert.is_not_nil(getmetatable(child.children))
    end)

    it("getLeavesOfSet()", function()
        local child1 = Tree.new()
        local child2 = Tree.new()
        tree:addChild(child1)
        tree:addChild(child2)
        child2:addChild(makeTree(4,2,{}))

        local child1a = Tree.new()
        child1a:addChild(makeTree(1,7,{}))

        local child1b = Tree.new()
        child1b:addChild(makeTree(5,1,{}))

        child1:addChild(child1a)
        child1:addChild(child1b)

        local result = Tree.getLeavesOfSet{
            [child1b] = true,
            [child2] = true,
        }

        local leaveCount = 0
        for leaf in pairs(result) do
            assert.is_true(hasParent(leaf, child1b) or hasParent(leaf, child2))
            local c = 0
            for _ in pairs(leaf.children) do
                c = c + 1
            end
            assert.are.equals(c, 0)
            leaveCount = leaveCount + 1
        end
        assert.are.equals(leaveCount, 9)
    end)

    describe(":addChild()", function()
        it("new node", function()
            local child = Tree.new()
            tree:addChild(child)
            assert.is_true(tree.children[child])
            assert.is_nil(rawget(tree, "parent"))
            assert.are.equals(child.parent, tree)
            assert.are.equals(tree.childCount, 1)
        end)

        it("error if the node is inserted twice", function()
            local tree2 = Tree.new()
            local child = Tree.new()
            tree2:addChild(child)
            assert.error(function()
                tree:addChild(child)
            end)
        end)
    end)

    it(":getRoot()", function()
        local child1 = Tree.new()
        local child2 = Tree.new()
        tree:addChild(child1)
        child1:addChild(child2)

        assert.are.equals(tree, child2:getRoot())
    end)

    it(":forEachNode()", function()
        local nodeSet = {}
        nodeSet[tree] = true
        tree:addChild(makeTree(3, 3, nodeSet))

        local count = 0
        tree:forEachNode(function(node)
            assert.is_true(nodeSet[node])
            nodeSet[node] = nil
            count = count + 1
        end)
        assert.are.equals(count, 14)
    end)
end)

-- Tests if a node has a given ancestor.
--
-- Args:
-- * child: A Tree node.
-- * parent: Another Tree node.
--
-- Returns: True if parent is an ancestor of child. False otherwise.
--
hasParent = function(child, parent)
    local current = rawget(child, "parent")
    while current and current ~= parent do
        current = rawget(current, "parent")
    end
    return current == parent
end

-- Creates a new tree.
--
-- Args:
-- * height: Height of the generated tree.
-- * childCount: Number of children per non-terminal node.
-- * nodeSet: Set to fill with the generated nodes.
--
-- Returns: The root of the generated tree.
--
makeTree = function(height, childCount, nodeSet)
    local result = Tree.new()
    nodeSet[result] = true
    if height > 1 then
        for i=1,childCount do
            result:addChild(makeTree(height-1, childCount, nodeSet))
        end
    end
    return result
end
