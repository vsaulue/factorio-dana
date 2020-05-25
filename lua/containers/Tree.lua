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

local forEachNode
local Metatable

-- Class for representing tree data structures.
--
-- This is just a simple tree. No sorting, no balancing.
--
-- RO fields:
-- * children: the set of children trees of this tree.
-- * parent: Parent node in the tree.
--
-- Methods: see Metatable.__index.
--
local Tree = ErrorOnInvalidRead.new{
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

return Tree
