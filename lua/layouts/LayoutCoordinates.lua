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

-- Holds the data of a layout for a renderer.
--
-- Subtypes:
-- * Edge: placement data for an hyperedge { xMin=..., xMax=..., yMin=..., yMax=...}
-- * Vertex: placement data for a vertex { xMin=..., xMax=..., yMin=..., yMax=...}
--
-- Fields:
-- * edges: map of Edge objects, indexed by their indices from the input hypergraph.
-- * links: set of TreeLink objects.
-- * vertices: map of Vertex objects, indexed by their indices from the input hypergraph.
--
local LayoutCoordinates = ErrorOnInvalidRead.new{
    -- Creates a new LayoutCoordinates object.
    --
    -- Returns: The new coordinates object.
    --
    new = function()
        local result = ErrorOnInvalidRead.new{
            edges = ErrorOnInvalidRead.new(),
            links = ErrorOnInvalidRead.new(),
            vertices = ErrorOnInvalidRead.new(),
        }
        return result
    end,
}

return LayoutCoordinates
