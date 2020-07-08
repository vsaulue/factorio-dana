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

local min = math.min
local max = math.max

local Metatable
local updateAabb

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
-- * xMax: Maximum value on the X axis (bounding box).
-- * xMin: Minimum value on the X axis (bounding box).
-- * yMax: Maximum value on the Y axis (bounding box).
-- * yMin: Minimum value on the Y axis (bounding box).
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
        object.xMin = math.huge
        object.xMax = -math.huge
        object.yMin = math.huge
        object.yMax = -math.huge
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a LayoutCoordinates instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)

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

-- Metatable of the LayoutCoordinates class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds an edge record.
        --
        -- Args:
        -- * self: LayoutCoordinates object.
        -- * edgeIndex: Index of the edge.
        -- * edgeData: Edge record to add.
        --
        addEdge = function(self, edgeIndex, edgeData)
            local map = self.edges
            cLogger:assert(not rawget(map, edgeIndex), "Duplicate edge index.")
            map[edgeIndex] = edgeData
            updateAabb(self, edgeData)
        end,

        -- Adds a tree link.
        --
        -- Args:
        -- * self: LayoutCoordinates object.
        -- * treeLink: TreeLink to add.
        --
        addTreeLink = function(self, treeLink)
            self.links[treeLink] = true
            local xMin = math.huge
            local xMax = -math.huge
            local yMin = math.huge
            local yMax = -math.huge
            treeLink.tree:forEachNode(function(node)
                xMin = min(xMin, node.x)
                xMax = max(xMax, node.x)
                yMin = min(yMin, node.y)
                yMax = max(yMax, node.y)
            end)

            local halfLinkWidth = self.layoutParameters.linkWidth / 2
            updateAabb(self, {
                xMin = xMin - halfLinkWidth,
                xMax = xMax + halfLinkWidth,
                yMin = yMin - halfLinkWidth,
                yMax = yMax + halfLinkWidth,
            })
        end,

        -- Adds an edge record.
        --
        -- Args:
        -- * self: LayoutCoordinates object.
        -- * vertexIndex: Index of the vertex.
        -- * vertexData: Vertex record to add.
        --
        addVertex = function(self, vertexIndex, vertexData)
            local map = self.vertices
            cLogger:assert(not rawget(map, vertexIndex), "Duplicate vertex index.")
            map[vertexIndex] = vertexData
            updateAabb(self, vertexData)
        end,
    }
}

-- Updates the min/max values to contain the specified AABB.
--
-- Args:
-- * self: LayoutCoordinates object.
-- * aabb: AABB object to include in the layout's bounding box.
--
updateAabb = function(self, aabb)
    self.xMin = min(self.xMin, aabb.xMin)
    self.xMax = max(self.xMax, aabb.xMax)
    self.yMin = min(self.yMin, aabb.yMin)
    self.yMax = max(self.yMax, aabb.yMax)
end

return LayoutCoordinates
