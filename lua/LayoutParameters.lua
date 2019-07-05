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

-- Class holding data to compute final coordinates of stuff in a graph layout.
--
-- Coordinates returned by layout are "abstract": X and Y. It's up to the renderer to decide
-- which one is horizontal/vertical (or do fancier transforms).
--
-- Fields:
-- * edgeMinX: Minimum desired X-length of hyperedges.
-- * edgeMinY: Minimum desired Y-length of hyperedges.
-- * linkWidth: Width of links, including margins (if you want 0.1-wide links separated by 0.5 gaps, set it to 0.6).
-- * vertexMinX: Minimum desired X-length if vertices.
-- * vertexMinY: Minimum desired Y-length if vertices.
--
local LayoutParameters = {
    new = nil, -- implemented later
}

-- Metatable of the LayoutParameters class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        edgeMinX = 1,
        edgeMinY = 1,
        linkWidth = 1,
        vertexMinX = 1,
        vertexMinY = 1,
    },
}

-- Creates a new LayoutParameters object.
--
-- Args:
-- * object: table to turn into a LayoutParameter object (or nil to create a new object).
--
-- Returns: the new LayoutParameters object.
--
function LayoutParameters.new(object)
    local result = object or {}
    setmetatable(result, Metatable)
    return result
end

return LayoutParameters
