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

local AbstractNode = require("lua/layouts/AbstractNode")
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
-- * layoutParameters: LayoutParameters used to generate these coordinates.
-- * links: set of TreeLink objects.
-- * node[prepNodeIndex]: Map of AbstractNode objects, indexed by edge indices from the input hypergraph.
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
        object.links = ErrorOnInvalidRead.new()
        object.nodes = ErrorOnInvalidRead.new()
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

        ErrorOnInvalidRead.setmetatable(object.nodes)
        for _,node in pairs(object.nodes) do
            AbstractNode.Factory:restoreMetatable(node)
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
        -- * nodeIndex: Index of the node.
        -- * node: AbstractNode to add.
        --
        addNode = function(self, nodeIndex, nodeData)
            local map = self.nodes
            cLogger:assert(not rawget(map, nodeIndex), "Duplicate node index.")
            map[nodeIndex] = nodeData
            updateAabb(self, nodeData:getAABB())
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

            local halfWidth = self.layoutParameters.linkWidth / 2
            updateAabb(self, xMin - halfWidth, xMax + halfWidth, yMin - halfWidth, yMax + halfWidth)
        end,
    }
}

-- Updates the min/max values to contain the specified AABB.
--
-- Args:
-- * self: LayoutCoordinates object.
-- * xMin: Minimum value on the X axis of the AABB to include.
-- * xMax: Maximum value on the X axis of the AABB to include.
-- * yMin: Minimum value on the Y axis of the AABB to include.
-- * yMax: Maximum value on the Y axis of the AABB to include.
--
updateAabb = function(self, xMin, xMax, yMin, yMax)
    self.xMin = min(self.xMin, xMin)
    self.xMax = max(self.xMax, xMax)
    self.yMin = min(self.yMin, yMin)
    self.yMax = max(self.yMax, yMax)
end

return LayoutCoordinates
