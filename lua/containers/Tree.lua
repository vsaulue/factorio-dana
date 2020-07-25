-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "Tree"}

local getLeavesOfSetImpl
local forEachNode
local Metatable

-- Class for representing tree data structures.
--
-- This is just a simple tree. No sorting, no balancing.
--
-- RO fields:
-- * childCount: Number of children of this node.
-- * children: the set of children trees of this tree.
-- * parent: Parent node in the tree.
--
-- Methods: see Metatable.__index.
--
local Tree = ErrorOnInvalidRead.new{
    -- Computes all the leaf nodes of a given set of nodes.
    --
    -- Args:
    -- * setofNodes: Set of nodes.
    --
    -- Returns: a set containing all the leaf nodes from the argument.
    --
    getLeavesOfSet = function(setOfNodes)
        local visitedSet = {}
        local resultSet = ErrorOnInvalidRead.new()
        for node in pairs(setOfNodes) do
            getLeavesOfSetImpl(node, visitedSet, resultSet)
        end
        return resultSet
    end,

    -- Creates a new Tree object.
    --
    -- Args:
    -- * object: Table to turn into a Tree object (or null for a new object).
    --
    -- Returns: The argument turned into a Tree object, or a new Tree object.
    --
    new = function(object)
        local result = object or {}
        result.children = ErrorOnInvalidRead.new()
        result.childCount = 0
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a Tree object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        forEachNode(object, function(node)
            setmetatable(node, Metatable)
            ErrorOnInvalidRead.setmetatable(node.children)
        end)
    end,
}

-- Metatable of the Tree class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a new child to this node.
        --
        -- Args:
        -- * self: Tree object (new parent).
        -- * newChild: Tree object to add as self's child.
        --
        addChild = function(self, newChild)
            cLogger:assert(not rawget(newChild, "parent"), "attempt to insert a subtree in 2 different trees.")
            newChild.parent = self
            self.children[newChild] = true
            self.childCount = self.childCount + 1
        end,

        -- Gets the root node of this tree.
        --
        -- Args:
        -- * self: Tree object.
        --
        -- returns: The root node owning self.
        --
        getRoot = function(self)
            local result = self
            local next = rawget(self, "parent")
            while next do
                result = next
                next = rawget(next, "parent")
            end
            return result
        end,

        -- Runs a function on each node of the tree.
        --
        -- The callback will be called exactly once per node. The order is implementation defined.
        --
        -- Args:
        -- * self: Tree object.
        -- * callback: function to call on each node.
        --
        forEachNode = function(self, callback)
            callback(self)
            for child in pairs(self.children) do
                forEachNode(child, callback)
            end
        end,
    },
}

forEachNode = Metatable.__index.forEachNode

-- Computes the set of leaf nodes from a specific node.
--
-- Args:
-- * node: Starting node.
-- * visitedSet: Set of already nodes already visited by this function.
-- * resultSet: Set of leaves.
--
getLeavesOfSetImpl = function(node, visitedSet, resultSet)
    if not visitedSet[node] then
        local count = 0
        visitedSet[node] = true
        for child in pairs(node.children) do
            getLeavesOfSetImpl(child, visitedSet, resultSet)
            count = count + 1
        end
        if count == 0 then
            resultSet[node] = true
        end
    end
end

return Tree
