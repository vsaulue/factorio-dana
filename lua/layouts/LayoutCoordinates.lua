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
local TreeLink = require("lua/layouts/TreeLink")

local cLogger = ClassLogger.new{className = "LayoutCoordinates"}

-- Holds the data of a layout for a renderer.
--
-- Subtypes:
-- * Edge: placement data for an hyperedge { xMin=..., xMax=..., yMin=..., yMax=...}
-- * Vertex: placement data for a vertex { xMin=..., xMax=..., yMin=..., yMax=...}
--
-- RO Fields:
-- * edges: map of Edge objects, indexed by their indices from the input hypergraph.
-- * layoutParameters: LayoutParameters used to generate these coordinates.
-- * links: set of TreeLink objects.
-- * vertices: map of Vertex objects, indexed by their indices from the input hypergraph.
--
local LayoutCoordinates = ErrorOnInvalidRead.new{
    -- Creates a new LayoutCoordinates object.
    --
    -- Returns: The new coordinates object.
    --
    new = function(object)
        cLogger:assertField(object, "layoutParameters")
        object.edges = ErrorOnInvalidRead.new()
        object.links = ErrorOnInvalidRead.new()
        object.vertices = ErrorOnInvalidRead.new()
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of a LayoutCoordinates instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)

        ErrorOnInvalidRead.setmetatable(object.edges)
        for _,edgeData in pairs(object.edges) do
            ErrorOnInvalidRead.setmetatable(edgeData)
        end

        ErrorOnInvalidRead.setmetatable(object.vertices)
        for _,vertexData in pairs(object.vertices) do
            ErrorOnInvalidRead.setmetatable(vertexData)
        end

        ErrorOnInvalidRead.setmetatable(object.links)
        for treeLink in pairs(object.links) do
            TreeLink.setmetatable(treeLink)
        end
    end,
}

return LayoutCoordinates
