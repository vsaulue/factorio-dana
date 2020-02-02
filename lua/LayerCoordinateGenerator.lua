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

local ChannelTreeBuilder = require("lua/ChannelTreeBuilder")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayoutCoordinates = require("lua/LayoutCoordinates")
local Logger = require("lua/Logger")

-- Helper class to compute the final coordinates of a LayerLayout object.
--
-- This class is private (not accessible from other files): it is just an intermediate
-- used during the layout generation.
--
-- Subtypes:
-- * LayerEntryPosition: Class holding placement data of a specific entry.
--   * output: placement data of this entry, returned in the LayoutCoordinates object.
--   * inboundNodes[channelIndex]: Tree node of the given channel index for inbound slots.
--   * outboundNodes[channelIndex]: Tree node of the given channel index for outbound slots.
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
local function processChannelLayer(self, lRank, yMin)
    local channelLayer = self.layout.channelLayers[lRank]
    local y = yMin
    for cRank=1,channelLayer.order.count do
        local channelIndex = channelLayer.order[cRank]
        local channelTree = null
        y = y + self.params.linkWidth
        local newTree = ChannelTreeBuilder.run(channelLayer, channelIndex, self.entryPositions, y)
        local category = "forward"
        if not channelIndex.isForward then
            category = "backward"
        end
        local treeLink = ErrorOnInvalidRead.new{
            category = category,
            tree = newTree,
        }
        self.result.links[treeLink] = true
    end
    return y + self.params.linkWidth
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
        entryPositions = ErrorOnInvalidRead.new{
            edge = result.edges,
            linkNode = ErrorOnInvalidRead.new(),
            vertex = result.vertices,
        },
        layout = layout,
        params = params,
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
    for layerId=1,layout.layers.entries.count do
        local layer = layout.layers.entries[layerId]
        local x = 0
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryType = entry.type
            local maxSlotsCount = math.max(entry.inboundSlots.count, entry.outboundSlots.count)
            local xLength = math.max(typeToMinX[entryType], params.linkWidth * maxSlotsCount)
            local xMargin = typeToMarginX[entryType]
            x = x + xMargin
            local entryRecord = ErrorOnInvalidRead.new{
                output = ErrorOnInvalidRead.new{
                    xMin = x,
                    xMax = x + xLength,
                },
                inboundNodes = ErrorOnInvalidRead.new(),
                outboundNodes = ErrorOnInvalidRead.new(),
            }
            if entryType ~= "linkNode" then
                local tableName = "vertices"
                if entryType == "edge" then
                    tableName = "edges"
                end
                self.result[tableName][entry.index] = entryRecord.output
            end
            self.entryPositions[entry] = entryRecord
            x = x + xLength + xMargin
        end
    end
    local channelLayers = layout.channelLayers
    local y = 0
    for layerId=1,layout.layers.entries.count do
        y = processChannelLayer(self, layerId, y)
        local layer = self.layout.layers.entries[layerId]
        local yMiddle = y + yLayerLength / 2
        for rank=1,layer.count do
            local entry = layer[rank]
            local yHalfLength = typeToMinY[entry.type] / 2
            local layerEntryPos = self.entryPositions[entry]
            layerEntryPos.output.yMin = yMiddle - yHalfLength
            layerEntryPos.output.yMax = yMiddle + yHalfLength
        end
        y = y + yLayerLength
    end
    processChannelLayer(self, layout.layers.entries.count + 1, y)

    for layerId=1,layout.layers.entries.count do
        local layer = self.layout.layers.entries[layerId]
        for rank=1,layer.count do
            local entry = layer[rank]
            local layerEntryPos = self.entryPositions[entry]
            local yMin = layerEntryPos.output.yMin
            for _,treeNode in pairs(layerEntryPos.inboundNodes) do
                treeNode.y = yMin
            end
            local yMax = layerEntryPos.output.yMax
            for _,treeNode in pairs(layerEntryPos.outboundNodes) do
                treeNode.y = yMax
            end
        end
    end

    return result
end

return LayerCoordinateGenerator
