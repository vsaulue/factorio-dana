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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayerXPassBlock = require("lua/layouts/layer/coordinates/LayerXPassBlock")
local OrderedSet = require("lua/containers/OrderedSet")

local barycenterPass
local firstPass
local fixConflicts
local Parsers

-- Helper library to assign an X coordinate to entries in LayerCoordinateGenerator.
--
local LayerXPass = ErrorOnInvalidRead.new{
    -- Computes the X coordinate of all entries.
    --
    -- Args:
    -- * self: LayerCoordinateGenerator object.
    --
    run = function(layerCoordinateGenerator)
        local layerIdMaxLength = firstPass(layerCoordinateGenerator)

        local layout = layerCoordinateGenerator.layout
        local entryPositions = layerCoordinateGenerator.entryPositions

        for layerId=layerIdMaxLength-1, 1, -1 do
            barycenterPass(layerCoordinateGenerator, layerId, Parsers.HighToLow)
        end

        for layerId=layerIdMaxLength+1, layout.layers.entries.count do
            barycenterPass(layerCoordinateGenerator, layerId, Parsers.LowToHigh)
        end
    end,
}

-- Runs a barycenter algorithm to computes the X coordinates in a layer.
--
-- This algorithm initially computes an X offset for each entry as the barycenter of connected entries
-- from an adjacent layer (the `parser` argument determines the one to use). Then a correction pass is
-- run to fix any overlap/permutation.
--
-- Args:
-- * layerCoordinateGenerator: LayerCoordinateGenerator object.
-- * layerId: Index of the layer to modify.
-- * parser: An object from the `Parsers` table, used to select which adjacent layer to use for input coordinates.
--
barycenterPass = function(layerCoordinateGenerator, layerId, parser)
    local layout = layerCoordinateGenerator.layout
    local layer = layout.layers.entries[layerId]
    if layer.count > 0 then
        local entryPositions = layerCoordinateGenerator.entryPositions
        local channelLayer = layout.channelLayers[layerId + parser.ChannelLayerOffset]

        local channelsAvgX = {}
        for linkIndex,entries in pairs(channelLayer[parser.ChannelLayerFar]) do
            local totalX = 0
            local count = entries.count
            if count > 0 then
                for i=1,count do
                    local entry = entries[i]
                    totalX = totalX + entryPositions[entry]:getNode(linkIndex, parser.EntryPosIsFarLow).x
                end
                channelsAvgX[linkIndex] = totalX / count
            end
        end

        local blocks = OrderedSet.new()
        local previousBlock = nil
        local noParents = Array.new()
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryPos = entryPositions[entry]
            local count = 0
            local oldXMin = entryPos.output:getXMin()
            local newXMin = 0
            for linkIndex,node in pairs(entryPos[parser.EntryPosNear]) do
                local channelX = channelsAvgX[linkIndex]
                if channelX then
                    local offsetX = node.x - oldXMin
                    newXMin = newXMin + channelX - offsetX
                    count = count + 1
                end
            end

            if count > 0 then
                local newBlock = LayerXPassBlock.make(entryPos, newXMin / count, count)
                if noParents.count > 0 then
                    if previousBlock then
                        -- Note: maybe spacing them evenly between newBlock & previousBlock might be nicer.
                        previousBlock:appendEntries(noParents)
                    else
                        noParents = newBlock:prependEntries(noParents)
                    end
                    noParents.count = 0
                end
                blocks:pushBack(newBlock)
                previousBlock = newBlock
            else
                noParents:pushBack(entryPos)
            end
        end


        if previousBlock then
            previousBlock:appendEntries(noParents)

            fixConflicts(blocks)

            local End = blocks.End
            local block = blocks.forward[blocks.Begin]
            while block ~= End do
                block:apply()
                block = blocks.forward[block]
            end
        end
    end
end

-- Initializes the X coordinates of each entries, witha  simple "left align" algorithm.
--
-- Args:
-- * LayerCoordinateGenerator: LayerCoordinateGenerator object.
--
-- Returns: The index of the widest layer (X length).
--
firstPass = function(layerCoordinateGenerator)
    local entries = layerCoordinateGenerator.layout.layers.entries
    local xLengthMax = - math.huge
    local layerIdMaxLength = nil
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local x = 0
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryRecord = layerCoordinateGenerator.entryPositions[entry]
            local xLength = entryRecord.output:getXLength(false)
            local xMargin = entryRecord.output.xMargin
            x = x + xMargin
            entryRecord:setXMin(x)
            x = x + xLength + xMargin
        end
        if x > xLengthMax then
            xLengthMax = x
            layerIdMaxLength = layerId
        end
    end
    return layerIdMaxLength
end

-- Runs a conflict resolution algorithm on a sequence of blocks.
--
-- This algorithm merges/moves blocks around to ensure that X coordinates of blocks follow the order in the set
-- and don't overlap.
--
-- Args:
-- * blocks: OrderedSet of LayerXPassBlock to fix.
--
fixConflicts = function(blocks)
    local End = blocks.End
    local forward = blocks.forward
    repeat
        local noConflicts = true
        local currentBlock = forward[blocks.Begin]
        local nextBlock = forward[currentBlock]
        while nextBlock ~= End do
            local cMax = currentBlock.xCenterOfMass + currentBlock.xMaxOffset
            local nMin = nextBlock.xCenterOfMass + nextBlock.xMinOffset
            if cMax > nMin then
                noConflicts = false
                currentBlock:mergeWith(nextBlock)
                blocks:remove(nextBlock)
            else
                currentBlock = nextBlock
            end
            nextBlock = forward[currentBlock]
        end
    until noConflicts
end

-- Records used determine which adjacent layer to use in the barycenter pass.
--
-- Fields:
-- * ChannelLayerFar: Field name in ChannelLayer. Entries to read in the input layer.
-- * ChannelLayerOffset: Value to add to the edited layer index to get the relevant channel layer.
-- * EntryPosNear: Field name in LayerEntryPosition. Nodes to read in the edited layer.
-- * EntryPosIsFarLow: True to read the low nodes in the input layer, false otherwise.
--
Parsers = ErrorOnInvalidRead.new{
    -- Object to compute the coordinates from the adjacent layer with higher index.
    HighToLow = ErrorOnInvalidRead.new{
        ChannelLayerFar = "highEntries",
        ChannelLayerOffset = 1,
        EntryPosNear = "highNodes",
        EntryPosIsFarLow = true,
    },

    -- Object to compute the coordinates from the adjacent layer with lower index.
    LowToHigh = ErrorOnInvalidRead.new{
        ChannelLayerFar = "lowEntries",
        ChannelLayerOffset = 0,
        EntryPosNear = "lowNodes",
        EntryPosIsFarLow = false,
    },
}

return LayerXPass
