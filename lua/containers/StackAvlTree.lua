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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Stack = require("lua/containers/Stack")

-- Forward declarations.
local Metatable

-- AVL tree with stack semantics.
--
-- Each node acts as a stack. A key can be associated to multiple values, and a node can hold
-- duplicate values.
--
-- RO Fields:
-- * count: Total number of values (NOT keys) in this tree.
-- * all fields inherited from AbstractAvlTree.
--
local StackAvlTree = ErrorOnInvalidRead.new{
    -- Creates a new empty StackAvlTree object.
    --
    -- Returns: The new StackAvlTree tree.
    --
    new = function()
        local result = AbstractAvlTree.new({
            count = 0,
            newNode = Stack.new,
        }, Metatable)
        setmetatable(result, Metatable)
        return result
    end,

    -- Common leaf value.
    NoChild = AbstractAvlTree.NoChild,
}

-- Aliases
local ParentMethods = AbstractAvlTree.Metatable.__index
local findNodeGreater = ParentMethods.findNodeGreater
local getOrCreateNode = ParentMethods.getOrCreateNode
local removeAt = ParentMethods.removeAt

-- Metatable of the StackAvlTree class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Inserts a value at the specified key (creates a new node if needed).
        --
        -- Args:
        -- * self: StackAvlTree object.
        -- * key: Key of the node in which the value will be pushed.
        -- * value: Value to push.
        --
        push = function(self, key, value)
            local node = getOrCreateNode(self, key)
            node:push(value)
            self.count = self.count + 1
        end,

        -- Pops a value from the first node whose key is greater than the argument.
        --
        -- Args:
        -- * self: StackAvlTree object.
        -- * key: Lower bound of the key to look for.
        -- * isStrict: True if the key of the selected mode must be strictly greater. False to allow equality.
        --
        -- Returns:
        -- * The key of the found node (or nil if no such node exists).
        -- * The value popped from the found node (or nil if no node was found).
        --
        popGreater = function(self, key, isStrict)
            local foundKey,value
            local node,stack = findNodeGreater(self, key, isStrict)
            if node then
                foundKey = node.key
                value = node:pop()
                if node.topIndex == 0 then
                    removeAt(self, node, stack)
                end
                self.count = self.count - 1
            end
            return foundKey,value
        end,
    },
}

return StackAvlTree
