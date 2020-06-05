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

local Array = require("lua/containers/Array")
local ChannelRouter = require("lua/layouts/layer/coordinates/ChannelRouter")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayerEntryPosition = require("lua/layouts/layer/coordinates/LayerEntryPosition")
local LayoutCoordinates = require("lua/layouts/LayoutCoordinates")
local TreeLink = require("lua/layouts/TreeLink")
local Logger = require("lua/logger/Logger")
local Stack = require("lua/containers/Stack")

-- Helper class to compute the final coordinates of a LayerLayout object.
--
-- This class is private (not accessible from other files): it is just an intermediate
-- used during the layout generation.
--
-- Fields:
-- * channelRouters[i]: ChannelRouter object corresponding to the i-th channel layer.
-- * entryPositions[entry]: LayerEntryPosition object associated to a specific entry.
-- * layout: Input LayerLayout instance.
-- * params: LayoutParameters object, describing constraints for the coordinates of elements.
-- * result: Output LayoutCoordinates object.
--
local LayerCoordinateGenerator = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local addTreeLink
local createEntryCoordinateRecords
local computeX
local computeY
local generateTreeLinks
local generateTreeLinksFromNode
local initChannelRouters
local processChannelLayer

-- Creates and adds a tree link to the generated layout.
--
-- Args:
-- * self: LayerCoordinateGenerator object being built.
-- * rootNode: root of the tree link.
-- * isForward: True for forward links, false for backward links.
--
addTreeLink = function(self, rootNode, isForward)
    local category = "forward"
    if not isForward then
        category = "backward"
    end
    local treeLink = TreeLink.new{
        category = category,
        tree = rootNode,
    }
    self.result.links[treeLink] = true
end

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
            local maxSlotsCount = math.max(entry.lowSlots.count, entry.outboundSlots.count)
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

-- Computes the Y coordinates of entries & nodes.
--
-- Args:
-- * self: LayerCoordinateGenerator object.
--
computeY = function(self)
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
    local routers = self.channelRouters
    local y = 0
    for layerId=1,entries.count do
        y = routers[layerId]:setY(y)
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
    routers[entries.count + 1]:setY(y)
end

-- Creates a tree links for all the channel indices of a channel layers.
--
-- All trees will be stored in self.result.links.
--
-- Args:
-- * self: LayerCoordinateGenerator object being build.
--
generateTreeLinks = function(self)
    local layers = self.layout.layers.entries
    local entryPositions = self.entryPositions
    for layerId=1,layers.count do
        local layer = layers[layerId]
        for entryRank=1,layer.count do
            local entry = layer[entryRank]
            if entry.type == "vertex" then
                local entryPos = entryPositions[entry]
                generateTreeLinksFromNode(self, entryPos.inboundNodes, layerId)
                generateTreeLinksFromNode(self, entryPos.outboundNodes, layerId + 1)
            end
        end
    end
end

-- Generates a tree link for each tree node in a map.
--
-- The map must be indexed by the associated channelIndex (ex: LayerEntryPosition.inboundNodes).
-- The generated links will have the nodes in the map as root.
--
-- Args:
-- * self: LayerCoordinateGenerator object being built.
-- * nodes: Input map of ChannelIndex -> TreeNode.
-- * startLayerId: Index of the router associated with the input nodes.
--
generateTreeLinksFromNode = function(self, nodes, startLayerId)
    local channelRouters = self.channelRouters
    for channelIndex,rootNode in pairs(nodes) do
        local layerId = startLayerId
        local stack = Stack.new()
        local nextNode = rootNode
        while nextNode do
            local router = channelRouters[layerId]
            router:buildTree(channelIndex, nextNode, stack)
            local topIndex = stack.topIndex
            if topIndex > 0 then
                assert(topIndex == 1, "LayerCoordinateGenerator: invalid link structure.")
                local branch = stack:pop()
                if branch.isLow then
                    layerId = layerId - 1
                    nextNode = branch.entryPosition.inboundNodes[channelIndex]
                else
                    layerId = layerId + 1
                    nextNode = branch.entryPosition.outboundNodes[channelIndex]
                end
                branch.entryNode:addChild(nextNode)
            else
                nextNode = nil
            end
        end
        addTreeLink(self, rootNode, channelIndex.isForward)
    end
end

-- Initialises the LayerCoordinateGenerator.channelRouters field.
--
-- Creates a ChannelRouter object for each channel layer.
--
-- Args:
-- * self: LayerCoordinateGenerator object.
--
initChannelRouters = function(self)
    local channelLayers = self.layout.channelLayers
    local routers = self.channelRouters
    local count = channelLayers.count
    for i=1,count do
        local channelLayer = channelLayers[i]
        routers[i] = ChannelRouter.new{
            channelLayer = channelLayer,
            entryPositions = self.entryPositions,
            linkWidth = self.params.linkWidth,
        }
    end
    routers.count = count
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
        channelRouters = Array.new(),
        entryPositions = ErrorOnInvalidRead.new(),
        layout = layout,
        params = params,
        result = result,
    }

    createEntryCoordinateRecords(self)
    computeX(self)
    initChannelRouters(self)
    computeY(self)
    generateTreeLinks(self)

    return result
end

return LayerCoordinateGenerator
