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
local Tree = require("lua/containers/Tree")

-- Node in a TreeLink object.
--
-- RO Fields:
-- * x: X coordinate of this node.
-- * y: Y coordinate of this node.
-- * linkIndex (optional): LinkIndex object of this link. Field present only at the root of the tree.
-- * edgeIndex (optional): Index of the edge of this node. Field present only at the leaves of the tree.
-- * infoHint: Hint for the renderer that it's a good node to place direction/vertex info.
-- + inherited from Tree.
--
--
local TreeLinkNode = ErrorOnInvalidRead.new{
    -- Creates a new TreeLinkNode object.
    --
    -- Args:
    -- * object: Table to turn into a TreeLinkNode object.
    --
    -- Returns: The argument turned into a TreeLinkNode object.
    --
    new = function(object)
        local result = Tree.new(object)
        result.infoHint = rawget(result, "infoHint") or false
        return result
    end,

    setmetatable = Tree.setmetatable,
}

return TreeLinkNode
