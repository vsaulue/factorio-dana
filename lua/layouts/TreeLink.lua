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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local TreeLinkNode = require("lua/layouts/TreeLinkNode")

local cLogger = ClassLogger.new{className = "TreeLink"}

-- Class representing a tree shaped link in a layout.
--
-- RO fields:
-- * categoryIndex: Index of the associated LinkCategory.
-- * tree: TreeLinkNode object which is the root of the link.
--
local TreeLink = ErrorOnInvalidRead.new{
    -- Creates a new TreeLink object.
    --
    -- Args:
    -- * object: Table to turn into a TreeLink object.
    --
    -- Returns: The argument turned into a TreeLink object.
    --
    new = function(object)
        cLogger:assertField(object, "categoryIndex")
        cLogger:assertField(object, "tree")
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of a TreeLink instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)
        TreeLinkNode.setmetatable(object.tree)
    end,
}

return TreeLink
