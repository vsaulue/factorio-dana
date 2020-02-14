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

-- Runs the slot sorting algorithm.
--
-- Args:
-- * layerLayout: LayerLayout object on which the algorithm will be run.
--
function SlotsSorter.run(layerLayout)
    local lCount = layerLayout.channelLayers.count
    for lRank=1,lCount do
        local xAvgHigh = ErrorOnInvalidRead.new()
        local xAvgLow = ErrorOnInvalidRead.new()
        local channelLayer = layerLayout.channelLayers[lRank]
        for cRank=1,channelLayer.order.count do
            local channelIndex = channelLayer.order[cRank]
            xAvgHigh[channelIndex] = avgEntryRank(layerLayout, channelLayer.highEntries[channelIndex])
            xAvgLow[channelIndex] = avgEntryRank(layerLayout,channelLayer.lowEntries[channelIndex])
        end
        if lRank > 1 then
            local layer = layerLayout.layers.entries[lRank-1]
            for eRank=1,layer.count do
                local entry = layer[eRank]
                entry.outboundSlots:sort(xAvgHigh)
            end
        end
        if lRank < lCount then
            local layer = layerLayout.layers.entries[lRank]
            for eRank=1,layer.count do
                local entry = layer[eRank]
                entry.inboundSlots:sort(xAvgLow)
            end
        end
    end
end

return SlotsSorter
