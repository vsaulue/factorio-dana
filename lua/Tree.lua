-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")

-- Class for representing tree data structures.
--
-- This is just a simple tree. No sorting, no balancing.
--
-- Fields:
-- * children: the set of children trees of this tree.
--
local Tree = {
    new = nil, -- implemented later
}

-- Creates a new Tree object.
--
-- Returns: A new tree node.
--
function Tree.new(object)
    local result = object or {}
    result.children = result.children or {}
    ErrorOnInvalidRead.setmetatable(result)
    ErrorOnInvalidRead.setmetatable(result.children)
    return result
end

return Tree
