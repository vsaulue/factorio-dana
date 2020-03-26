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

local ChannelRouter = require("lua/layouts/layer/coordinates/ChannelRouter")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayerEntryPosition = require("lua/layouts/layer/coordinates/LayerEntryPosition")
local LayoutCoordinates = require("lua/layouts/LayoutCoordinates")
local Logger = require("lua/Logger")

-- Helper class to compute the final coordinates of a LayerLayout object.
--
-- This class is private (not accessible from other files): it is just an intermediate
-- used during the layout generation.
--
-- Fields:
-- * entryPositions[entry]: LayerEntryPosition object associated to a specific entry.
-- * layout: Input LayerLayout instance.
-- * params: LayoutParameters object, describing constraints for the coordinates of elements.
-- * result: Output LayoutCoordinates object.
--
local LayerCoordinateGenerator = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local attachLinksToEntries
local createEntryCoordinateRecords
local computeX
local computeYAndLinks
local processChannelLayer

-- Creates empty coordinate records for each entry.
--
-- Args:
-- * self: LayerCoordinateGenerator object.
--
createEntryCoordinateRecords = function(self)
    local entries = self.layout.layers.entries
    for layerId=1,entries.count do
        local layer = entries[layerId]
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryType = entry.type
            local entryRecord = LayerEntryPosition.new{
                entry = entry,
            }
            if entryType ~= "linkNode" then
                local tableName = "vertices"
                if entryType == "edge" then
                    tableName = "edges"
                end
                self.result[tableName][entry.index] = entryRecord.output
            end
            self.entryPositions[entry] = entryRecord
        end
    end
end

-- Computes the X coordinate of all entries.
--
-- Args:
-- * self: LayerCoordinateGenerator object.
--
computeX = function(self)
    local params = self.params
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
    local entries = self.layout.layers.entries
    local xLengthMax = - math.huge
    local layerXLengths = ErrorOnInvalidRead.new()
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local x = 0
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryType = entry.type
            local maxSlotsCount = math.max(entry.inboundSlots.count, entry.outboundSlots.count)
            local xLength = math.max(typeToMinX[entryType], params.linkWidth * maxSlotsCount)
            local xMargin = typeToMarginX[entryType]
            x = x + xMargin
            local entryRecord = self.entryPositions[entry]
            entryRecord:initX(x, xLength)
            x = x + xLength + xMargin
        end
        if x > xLengthMax then
            xLengthMax = x
        end
        layerXLengths[layerId] = x
    end

    -- Center
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local xDelta = (xLengthMax - layerXLengths[layerId]) / 2
        for rank=1,layer.count do
            self.entryPositions[layer[rank]]:translateX(xDelta)
        end
    end
end

-- Computes the Y coordinates of entries & nodes, and the tree links.
--
-- All trees will be stored in self.result.links. The nodes attached to an entry will be properly
-- added to the corresponding LayerEntryPosition objects inside self.entryPositions.
--
-- Args:
-- * self: LayerCoordinateGenerator object.
--
computeYAndLinks = function(self)
    local params = self.params
    local typeToMinY = ErrorOnInvalidRead.new{
        edge = params.edgeMinY,
        linkNode = 0,
        vertex = params.vertexMinY,
    }
    local yLayerLength = math.max(
        params.edgeMinY + 2 * params.edgeMarginY,
        params.vertexMinY + 2 * params.vertexMarginY
    )
    local entries = self.layout.layers.entries
    local channelLayers = self.layout.channelLayers
    local y = 0
    for layerId=1,entries.count do
        y = processChannelLayer(self, layerId, y)
        local layer = entries[layerId]
        local yMiddle = y + yLayerLength / 2
        for rank=1,layer.count do
            local entry = layer[rank]
            local yHalfLength = typeToMinY[entry.type] / 2
            local layerEntryPos = self.entryPositions[entry]
            layerEntryPos:initY(yMiddle - yHalfLength, yMiddle + yHalfLength)
        end
        y = y + yLayerLength
    end
    processChannelLayer(self, entries.count + 1, y)
end

-- Creates a tree links for all the channel indices of a channel layers.
--
-- All trees will be stored in self.result.links. The nodes attached to an entry will be properly
-- added to the corresponding LayerEntryPosition objects inside self.entryPositions. The Y
-- field of these nodes are NOT set by this function.
--
-- Args:
-- * self: LayerCoordinateGenerator object being build.
-- * lRank: Rank of the channel layer to build.
-- * yMin: maximum "y" coordinate of objects in the last layer.
--
-- Returns: The "y" coordinate from which the next layer should be placed.
--
processChannelLayer = function(self, lRank, yMin)
    local channelLayer = self.layout.channelLayers[lRank]
    local router = ChannelRouter.new{
        channelLayer = channelLayer,
        entryPositions = self.entryPositions,
        linkWidth = self.params.linkWidth,
    }
    for channelIndex,tree in pairs(router.roots) do
        local category = "forward"
        if not channelIndex.isForward then
            category = "backward"
        end
        local treeLink = ErrorOnInvalidRead.new{
            category = category,
            tree = tree,
        }
        self.result.links[treeLink] = true
    end
    return router:setY(yMin)
end

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
        entryPositions = ErrorOnInvalidRead.new(),
        layout = layout,
        params = params,
        result = result,
    }

    createEntryCoordinateRecords(self)
    computeX(self)
    computeYAndLinks(self)

    return result
end

return LayerCoordinateGenerator
