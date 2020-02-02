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
-- * TreeLink a table with two fields:
--     * category: a string ("forward" or "backward")
--     * tree: a Tree object where:
--         * each node has the fields "x" and "y" (coordinates of this node).
--         * the root & leaves also have "type" and "index" entry, indicating which edge/vertex from the hypergraph
--           is connected at this point.
--
-- Fields:
-- * edges: map of Edge objects, indexed by their indices from the input hypergraph.
-- * links: set of TreeLink objects.
-- * vertices: map of Vertex objects, indexed by their indices from the input hypergraph.
--
local LayoutCoordinates = {
    new = nil, -- implemented later
}

-- Creates a new LayoutCoordinates object.
--
-- Returns: The new coordinates object.
--
function LayoutCoordinates.new()
    local result = ErrorOnInvalidRead.new{
        edges = ErrorOnInvalidRead.new(),
        links = ErrorOnInvalidRead.new(),
        vertices = ErrorOnInvalidRead.new(),
    }
    return result
end

return LayoutCoordinates
