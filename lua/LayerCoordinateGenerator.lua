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

local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")
local LayoutCoordinates = require("lua/LayoutCoordinates")
local Logger = require("lua/Logger")
local Tree = require("lua/Tree")

-- Helper class to compute the final coordinates of a LayerLayout object.
--
-- This class is private (not accessible from other files): it is just an intermediate
-- used during the layout generation.
--
-- Fields:
-- * entryPositions[type][index]: Placement data of the entry with the given type & index.
-- * layout: Input LayerLayout instance.
-- * result: Output LayoutCoordinates object.
--
local LayerCoordinateGenerator = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    getMiddleEntryPos = nil, -- implemented later

    buildTree = nil, -- implemented later

    buildTreeImpl = nil, -- implemented later
}

-- Computes the coordinates of each elements of a LayerLayout object.
--
-- Args:
-- * layout: LayerLayout object.
-- * params: LayoutParameters object, describing constraints for the coordinates of elements.
--
-- Returns: a LayoutCoordinates object.
--
function LayerCoordinateGenerator.run(layout, params)
    local result = LayoutCoordinates.new()
    local self = ErrorOnInvalidRead.new{
        entryPositions = ErrorOnInvalidRead.new{
            edge = result.edges,
            linkNode = ErrorOnInvalidRead.new(),
            vertex = result.vertices,
        },
        layout = layout,
        result = result,
    }
    local typeToMinX = ErrorOnInvalidRead.new{
        edge = params.edgeMinX,
        linkNode = params.linkWidth,
        vertex = params.vertexMinX,
    }
    local typeToMarginX = ErrorOnInvalidRead.new{
        edge = params.edgeMarginX,
        linkNode = 0,
        vertex = params.vertexMarginX,
    }
    local typeToMinY = ErrorOnInvalidRead.new{
        edge = params.edgeMinY,
        linkNode = 0,
        vertex = params.vertexMinY,
    }
    local yLayerLength = math.max(
        params.edgeMinY + 2 * params.edgeMarginY,
        params.vertexMinY + 2 * params.vertexMarginY
    )
    local middleY = yLayerLength / 2
    for layerId=1,layout.layers.entries.count do
        local layer = layout.layers.entries[layerId]
        local x = 0
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryType = entry.type
            local xLength = typeToMinX[entryType]
            local xMargin = typeToMarginX[entryType]
            x = x + xMargin
            local yHalfLength = typeToMinY[entryType] / 2
            self.entryPositions[entry.type][entry.index] = ErrorOnInvalidRead.new{
                xMin = x,
                xMax = x + xLength,
                yMin = middleY - yHalfLength,
                yMax = middleY + yHalfLength,
            }
            x = x + xLength + xMargin
        end
        middleY = middleY + 4 * yLayerLength
    end
    for _,pos in pairs(layout.layers.reverse.vertex) do
        local vertexEntry = layout.layers.entries[pos[1]][pos[2]]
        Impl.buildTree(vertexEntry, layout.layers.links.forward, self.entryPositions, result.links)
        Impl.buildTree(vertexEntry, layout.layers.links.backward, self.entryPositions, result.links)
    end
    return result
end

-- Gets the coordinates of the middle of an entry.
--
-- Args:
-- * entry: Entry which coordinates will be computed.
-- * entryPositions[type,index]: map of entries position data.
--
-- Returns: x,y coordinates of the middle of the entry.
--
function Impl.getMiddleEntryPos(entry, entryPositions)
    local entryPos = entryPositions[entry.type][entry.index]
    local entryMiddleX = (entryPos.xMin + entryPos.xMax) / 2
    local entryMiddleY = (entryPos.yMin + entryPos.yMax) / 2
    return entryMiddleX, entryMiddleY
end

-- Implementation of Impl.buildTree.
--
-- TODO: non-recursive implementation
--
-- Args:
-- * entry: Root of the tree being built.
-- * links: Map of links to use (ex: Layers.link.forward or Layers.links.backward).
-- * entryPositions[type,index]: Map holding the position of each entry.
--
-- Returns: A tree of the links from entry.
--
function Impl.buildTreeImpl(entry,links, entryPositions)
    local entryX, entryY = Impl.getMiddleEntryPos(entry, entryPositions)
    local result = Tree.new({
        x = entryX,
        y = entryY,
    })
    if entry.type == "linkNode" then
        for link in pairs(links[entry]) do
            local otherEntry = link:getOtherEntry(entry)
            local subtree = Impl.buildTreeImpl(otherEntry, links, entryPositions)
            result.children[subtree] = true
        end
    else
        if entry.type ~= "edge" then
            Logger.error("LayerLayout: link connecting multiple vertices together.")
        end
        result.type = entry.type
        result.index = entry.index
    end
    return result
end

-- Builds trees for each link starting from the specified vertex entry.
--
-- This function builds a tree of links starting from the given vertex entry. It
-- is only allowed to cross "linkNode" entries.
--
-- Args:
-- * entry: Vertex entry from which to start.
-- * links: Map of links to use (ex: Layers.link.forward or Layers.links.backward).
-- * entryPositions[type,index]: Map holding the position of each entry.
-- * output: The table in which to store the generated trees.
--
function Impl.buildTree(entry, links, entryPositions, output)
    local forwardCount = 0
    local entryX, entryY = Impl.getMiddleEntryPos(entry, entryPositions)
    local forwardTree = Tree.new({
        type = entry.type,
        index = entry.index,
        x = entryX,
        y = entryY,
    })
    local backwardCount = 0
    local backwardTree = Tree.new({
        type = entry.type,
        index = entry.index,
        x = entryX,
        y = entryY,
    })
    for link in pairs(links[entry]) do
        local otherEntry = link:getOtherEntry(entry)
        local newTree = Impl.buildTreeImpl(otherEntry, links, entryPositions)
        if link.channelIndex.isForward then
            forwardTree.children[newTree] = true
            forwardCount = forwardCount + 1
        else
            backwardTree.children[newTree] = true
            backwardCount = backwardCount + 1
        end
    end
    if forwardCount > 0 then
        local newTreeLink = ErrorOnInvalidRead.new{
            tree = forwardTree,
            category = "forward",
        }
        output[newTreeLink] = true
    end
    if backwardCount > 0 then
        local newTreeLink = ErrorOnInvalidRead.new{
            tree = backwardTree,
            category = "backward",
        }
        output[newTreeLink] = true
    end
end

return LayerCoordinateGenerator
