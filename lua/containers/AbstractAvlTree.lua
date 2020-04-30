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
local Logger = require("lua/logger/Logger")
local Stack = require("lua/containers/Stack")

-- Forward declarations & aliases.
local findNode
local findMaxAt
local findMinAt
local Metatable
local max = math.max
local min = math.min
local NoChild
local newNode
local rebalanceNode
local swapInStack
local trySimpleRemove
local updateAndRebalance

-- An abstract class for AVL trees.
--
-- All "find" methods returns the node (if found) and a stack. The later enables derived classes to conditionally
-- removes the node after checking its content using removeAt(), without navigating the tree again.
--
-- The navigation stack is always pushed/poped 2 by 2. These 2 values are:
-- * A Node object
-- * A string: either "lowerNode" or "greaterNode"
-- This represents how the tree was navigated to reach the node.
--
-- Subtypes:
-- * Node (abstract): a node in the tree.
-- **  balance: The height difference between children: height(greaterNode) - height(lowerNode)
-- **  greaterNode: Child tree containing all nodes will greater keys (a.k.a "right" node in usual representations).
-- **  key: Key of this node.
-- **  lowerNode: Child tree containing all nodes will lower keys (a.k.a "left" node in usual representations).
--
-- The actual class of the nodes can be anything that doesn't define/modify these fields.
--
-- RO fields:
-- * newNode: Constructor for new nodes.
-- * root: Current root of the tree (NoChild for an empty tree).
--
-- Methods: see Metatable.__index.
--
local AbstractAvlTree = ErrorOnInvalidRead.new{
    -- Creates a new AbstractAvlTree object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractAvlTree. Muse have a newNode field.
    -- * metatable: Actual metatable to set (or nil to use the abstract one).
    --
    -- Returns: object turned into the desired type.
    --
    new = function(object, metatable)
        assert(object.newNode, "AbstractAvlTree: missing mandatory 'newNode' field.")
        object.root = NoChild
        setmetatable(object, metatable or Metatable)
        return object
    end,

    -- Metatable of the AbstractAvlTree class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Finds the node at the given key.
            --
            -- Args:
            -- * self: AbstractAvlTree object.
            -- * key: Key to look for.
            --
            -- Returns:
            -- * The node if the key is present (nil otherwise).
            -- * A navigation stack.
            --
            findNode = function(self, key)
                local result = self.root
                local stack = Stack.new()
                while result ~= NoChild and result.key ~= key do
                    local side
                    if key < result.key then
                        side = "lowerNode"
                    else
                        side = "greaterNode"
                    end
                    stack:push2(result, side)
                    result = result[side]
                end
                if result == NoChild then
                    result = nil
                end
                return result,stack
            end,

            -- Finds the first node whose key is greater than a given value.
            --
            -- Args:
            -- * self: AbstractAvlTree object.
            -- * key: Lower bound of the key to look for.
            -- * isStrict: true if the node must have a strictly greater key; false to allow equality.
            --
            -- Returns:
            -- * The first node whose key is greater (or equal) than the argument. Nil if there is no such node.
            -- * A navigation stack.
            --
            findNodeGreater = function(self, key, isStrict)
                local node = self.root
                local result = nil
                local stack = Stack.new()
                local resultTopIndex = 0
                while node ~= NoChild and node.key ~= key do
                    local side
                    if key < node.key then
                        result = node
                        resultTopIndex = stack.topIndex
                        side = "lowerNode"
                    else
                        side = "greaterNode"
                    end
                    stack:push2(node, side)
                    node = node[side]
                end
                if node ~= NoChild then
                    if isStrict then
                        local greater = node.greaterNode
                        if greater ~= NoChild then
                            stack:push2(greater, "greaterNode")
                            result = findMinAt(greater, stack)
                        end
                    else
                        result = node
                    end
                else
                    stack.topIndex = resultTopIndex
                end
                return result,stack
            end,

            -- Gets the node at the given key (create & insert it if needed).
            --
            -- Args:
            -- * self: AbstractAvlTree object.
            -- * key: Key to look for.
            --
            -- Returns: The node in the tree with the given key (freshly created if it was not present).
            --
            getOrCreateNode = function(self, key)
                -- find location
                local result,stack = findNode(self, key)
                if not result then
                    result = newNode(self, key)
                    updateAndRebalance(self, stack, result, 1)
                end
                return result
            end,

            -- Removes the specified node.
            --
            -- Args:
            -- * self: AbstractAvlTree object.
            -- * deletedNode: Node to delete.
            -- * stack: Navigation stack used to access deletedNode.
            --
            removeAt = function(self, deletedNode, stack)
                local updatedNode = trySimpleRemove(deletedNode,stack)
                if not updatedNode then
                    local balance = deletedNode.balance
                    local nodeReplacingDeleted
                    stack:push(deletedNode)
                    local deletedStackId = stack.topIndex
                    if balance < 0 then
                        stack:push("lowerNode")
                        nodeReplacingDeleted = findMaxAt(deletedNode.lowerNode, stack)
                    else
                        stack:push("greaterNode")
                        nodeReplacingDeleted = findMinAt(deletedNode.greaterNode, stack)
                    end
                    updatedNode = trySimpleRemove(nodeReplacingDeleted)
                    swapInStack(self, stack, deletedStackId, nodeReplacingDeleted)
                end
                updateAndRebalance(self, stack, updatedNode, -1)
            end,
        },
    },

    -- Common leaf value.
    NoChild = ErrorOnInvalidRead.new(),
}

findNode = AbstractAvlTree.Metatable.__index.findNode
Metatable = AbstractAvlTree.Metatable
NoChild = AbstractAvlTree.NoChild

-- Finds the maximum node in a given subtree.
--
-- Args:
-- * node: Root of the subtree.
-- * stack: Navigation stack to fill.
--
-- Returns: The node with the maximum key in the given subtree.
--
findMaxAt = function(node, stack)
    local result = node
    local next = node.greaterNode
    while next ~= NoChild do
        stack:push2(result, "greaterNode")
        result = next
        next = next.greaterNode
    end
    return result
end

-- Finds the minimum node in a given subtree.
--
-- Args:
-- * node: Root of the subtree.
-- * stack: Navigation stack to fill.
--
-- Returns: The node with the minimum key in the given subtree.
--
findMinAt = function(node, stack)
    local result = node
    local next = node.lowerNode
    while next ~= NoChild do
        stack:push2(result, "lowerNode")
        result = next
        next = next.lowerNode
    end
    return result
end

-- Creates a new node for the tree.
--
-- Args:
-- * self: AbstractAvlTree object.
-- * key: Key of the new node.
--
newNode = function(self, key)
    local result = self.newNode()
    result.key = key
    result.balance = 0
    result.lowerNode = NoChild
    result.greaterNode = NoChild
    return result
end

-- Rebalances a given node after an insertion or deletion.
--
-- Prerequisites:
-- * the 2 subtrees are valid AVL trees.
-- * the balance of the current node is off only by one (== 2 or -2).
--
-- Args:
-- * node: Node to rebalance.
-- * prevDelta: Difference of height caused by the insertion/deletion & rebalances of the modified subtree.
--
-- Returns:
-- * The new root of the rebalanced subtree.
-- * The difference of height caused by the insertion/deletion & rebalances.
--
rebalanceNode = function(node, prevDelta)
    local nodeBalance = node.balance
    local srcSide = "lowerNode"
    local dstSide = "greaterNode"
    local factor = -1
    if nodeBalance > 0 then
        srcSide = "greaterNode"
        dstSide = "lowerNode"
        factor = 1
    end
    assert(factor * nodeBalance == 2, "AbstractAvlTree: invalid usage of rebalanceNode.")

    local newRoot
    local subNode = node[srcSide]
    local subBalance = subNode.balance
    local heightDelta
    if factor * subBalance < 0 then
        -- double rotation
        newRoot = subNode[dstSide]
        node[srcSide] = newRoot[dstSide]
        subNode[dstSide] = newRoot[srcSide]
        newRoot[srcSide] = subNode
        newRoot[dstSide] = node

        local rootBalance = newRoot.balance
        node.balance = - factor * max(factor * rootBalance, 0)
        subNode.balance = - factor * min(factor * rootBalance, 0)
        newRoot.balance = 0

        heightDelta = -1
    else
        -- simple rotation
        newRoot = subNode
        node[srcSide] = newRoot[dstSide]
        newRoot[dstSide] = node

        local newRootBalance = newRoot.balance - factor
        newRoot.balance = newRootBalance
        node.balance = -newRootBalance

        heightDelta = - factor * subBalance
    end
    return newRoot,heightDelta + prevDelta
end

-- Replaces a node in the tree, at the given index in a navigations stack.
--
-- It's the responsibility of the caller to ensure that the key of the new node doesn't break invariants
-- of the AVL tree.
--
-- Args:
-- * self: AbstractAvlTree object.
-- * stack: Navigation stack containing the node to remove.
-- * index: Index of the node to remove in the stack.
-- * newNode: Node to insert in the stack.
--
-- Returns: The new root of the subtree (or nil if this function can't perform the simple removal).
--
swapInStack = function(self, stack, index, newNode)
    local deletedNode = stack[index]
    newNode.balance = deletedNode.balance
    newNode.greaterNode = deletedNode.greaterNode
    newNode.lowerNode = deletedNode.lowerNode
    if index == 1 then
        self.root = newNode
    else
        stack[index-2][stack[index-1]] = newNode
    end
    stack[index] = newNode
end

-- Removes a node from the tree only if it has at least one empty subtree.
--
-- If the given node has 2 non-empty subtrees, the function does nothing.
--
-- Args:
-- * node: Node to remove.
-- * stack: Navigation stack to reach the node.
--
trySimpleRemove = function(node, stack)
    local newRoot = nil
    local greaterNode = node.greaterNode
    local lowerNode = node.lowerNode
    if lowerNode == NoChild then
        newRoot = greaterNode
    else
        if greaterNode == NoChild then
            newRoot = lowerNode
        end
    end
    return newRoot
end

-- Rebalances the full tree after a single insertion/deletion at a leaf.
--
-- Args:
-- * self: AbstractAvlTree object.
-- * stack: Navigation stack leading to the inserted/removed node.
-- * leafNode: Node to set at the end of the stack (either the new node, or the node replacing the deleted one).
-- * heightDelta: Height difference of the subtree at the end of the navigation stack (1 or -1).
--
updateAndRebalance = function(self, stack, leafNode, heightDelta)
    local curHeightDelta = heightDelta
    local node = leafNode
    while stack.topIndex > 0 and curHeightDelta ~= 0 do
        local parent,side = stack:pop2()
        local balance = parent.balance
        if side == "greaterNode" then
            balance = balance + curHeightDelta
            if balance < 0 or (balance == 0 and curHeightDelta == 1) then
                curHeightDelta = 0
            end
        else
            assert(side == "lowerNode", "AbstractAvlTree: corrupted stack.")
            balance = balance - curHeightDelta
            if balance > 0 or (balance == 0 and curHeightDelta == 1) then
                curHeightDelta = 0
            end
        end
        parent.balance = balance
        parent[side] = node
        if balance >= 2 or balance <= -2 then
            parent,curHeightDelta = rebalanceNode(parent, curHeightDelta)
        end
        node = parent
    end
    if stack.topIndex == 0 then
        self.root = node
    else
        local parent,side = stack:pop2()
        parent[side] = node
    end
end

return AbstractAvlTree
