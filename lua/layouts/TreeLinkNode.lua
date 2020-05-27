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
-- + inherited from Tree.
--
local TreeLinkNode = ErrorOnInvalidRead.new{
    new = Tree.new,

    setmetatable = Tree.setmetatable,
}

return TreeLinkNode
