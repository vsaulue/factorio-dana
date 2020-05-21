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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

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
            local previousParent = rawget(newChild, "parent")
            if previousParent then
                previousParent.children[newChild] = nil
            end
            newChild.parent = self
            self.children[newChild] = true
        end,
    },
}

return Tree
