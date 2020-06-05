-- This file is part of Dana.
-- Copyright (C) 2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

-- Helper library to sort slots of entries in a LayerLayout object.
--
-- The algorithm ensures that for the the inbound (or outbound) slots of any entry,
-- the slots placement allows to draw all its 2-entry channels without them crossing
-- each other.
--
local SlotsSorter = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local avgEntryRank
local getOtherLayerLength
local sortSlotsSide

-- Dummy index, used to insert a tail sentinel value in some arrays.
local DummyIndex = "dummy"

-- Structure holding information to configure the algorithm for either inbound or outbound slots.
--
-- RO Fields:
-- * channelLayerOffset: Difference between a layer index, and the index of the channel layer to parse.
-- * otherLayerOffset: Difference between the layer index, and the index of the adjacent layer to parse.
-- * nearEntriesName: Name of the field in ChannelLayer containing the entries of the current layer.
-- * farEntriesName: Name of the field in ChannelLayer containing the entries of the other layer.
-- * slotsName: Name of the field in LayerEntry of the slots to sort.
--
local SlotSorterParser = ErrorOnInvalidRead.new{
    -- Parser configuration for highSlots.
    HighSlots = ErrorOnInvalidRead.new{
        channelLayerOffset = 1,
        otherLayerOffset = 1,
        nearEntriesName = "lowEntries",
        farEntriesName = "highEntries",
        slotsName = "highSlots",
    },

    -- Parser configuration for lowSlots.
    LowSlots = ErrorOnInvalidRead.new{
        channelLayerOffset = 0,
        otherLayerOffset = -1,
        nearEntriesName = "highEntries",
        farEntriesName = "lowEntries",
        slotsName = "lowSlots",
    },
}

-- Computes the average entry rank of an array of entries.
--
-- Args:
-- * layerLayout: LayerLayout object containing the entries.
-- * channelEntries: Array of entries to evaluate.
--
-- Returns: the average rank of the entries (or 0 if the array is empty).
--
avgEntryRank = function(layerLayout, channelEntries)
    local result = 0
    local count = channelEntries.count
    if count > 0 then
        local sum = 0
        for i=1,count do
            local entry = channelEntries[i]
            local entryRank = layerLayout.layers.reverse[entry.type][entry.index][2]
            sum = sum + entryRank
        end
        result = sum / count
    end
    return result
end

-- Gets the length of the other layer of the parsed channel layer.
--
-- Args:
-- * layerLayout: LayerLayout object on which the algorithm will be run.
-- * lRank: Index of the layer to process.
-- * parser: SlotSorterParser object, determining which slots will be sorted.
--
getOtherLayerLength = function(layerLayout, lRank, parser)
    local lRank2 = lRank + parser.otherLayerOffset
    local result = 0
    if 1 <= lRank2 and lRank2 <= layerLayout.layers.entries.count then
        result = layerLayout.layers.entries[lRank2].count
    end
    return result
end

-- Runs the slot sorting algorithm on a specific layer, for a specific side.
--
-- Args:
-- * layerLayout: LayerLayout object on which the algorithm will be run.
-- * lRank: Index of the layer to process.
-- * parser: SlotSorterParser object, determining which slots will be sorted.
--
sortSlotsSide = function(layerLayout, lRank, parser)
    local layer = layerLayout.layers.entries[lRank]
    local doubleLength = 1 + 2 * (layer.count + getOtherLayerLength(layerLayout, lRank, parser))
    local channelLayer = layerLayout.channelLayers[lRank+parser.channelLayerOffset]
    local xTargets = ErrorOnInvalidRead.new()
    local horizontalXAvg = ErrorOnInvalidRead.new()
    local horizontalOrder = Array.new()
    for channelIndex,farEntries in pairs(channelLayer[parser.farEntriesName]) do
        local nearEntries = channelLayer[parser.nearEntriesName][channelIndex]
        if farEntries.count == 0 then
            local avg = avgEntryRank(layerLayout, nearEntries)
            horizontalXAvg[channelIndex] = avg
            xTargets[channelIndex] = doubleLength - avg
            horizontalOrder:pushBack(channelIndex)
        else
            xTargets[channelIndex] = avgEntryRank(layerLayout, farEntries)
        end
    end
    horizontalOrder:sort(horizontalXAvg)
    horizontalOrder:pushBack(DummyIndex)
    horizontalXAvg[DummyIndex] = math.huge
    local flipIndex = 1
    local nextFlipX = horizontalXAvg[horizontalOrder[1]]
    for eRank=1,layer.count do
        local entry = layer[eRank]
        while nextFlipX < eRank do
            local channelIndex = horizontalOrder[flipIndex]
            xTargets[channelIndex] = - horizontalXAvg[channelIndex]
            flipIndex = flipIndex + 1
            nextFlipX = horizontalXAvg[horizontalOrder[flipIndex]]
        end
        entry[parser.slotsName]:sort(xTargets)
    end
end

-- Runs the slot sorting algorithm.
--
-- Args:
-- * layerLayout: LayerLayout object on which the algorithm will be run.
--
function SlotsSorter.run(layerLayout)
    for lRank=1,layerLayout.layers.entries.count do
        sortSlotsSide(layerLayout, lRank, SlotSorterParser.LowSlots)
        sortSlotsSide(layerLayout, lRank, SlotSorterParser.HighSlots)
    end
end

return SlotsSorter
