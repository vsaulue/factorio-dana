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

local mergeArrays
local Metatable

-- Class holding contiguous LayerEntryPosition objects within a layer.
--
-- RO Fields:
-- * entries: Array of entries in this block.
-- * xCenterOfMass: Absolute X coordinate of the center of mass of this block.
-- * xMinOffset: Offset to add to xCenterOfMass to get the lower bound on the X axis.
-- * xMaxOffset: Offset to add to xCenterOfMass to get the upper bound on the X axis.
-- * weight: Weight of this block.
--
local LayerXPassBlock = ErrorOnInvalidRead.new{
    -- Creates a new block, wraping a single LayerEntryPosition object.
    --
    -- Args:
    -- * entryPos: LayerEntryPosition object to wrap.
    -- * xMin: Lower bound of the X coordinates of this block.
    -- * weight: Weight of the new block.
    --
    -- Returns: The new block wrapping the argument entry.
    --
    make = function(entryPos, xMin, weight)
        local node = entryPos.output
        local xHalfLength = node:getXLength(false) / 2
        local xCenter = xMin + xHalfLength
        local xOffset = xHalfLength + node.xMargin
        local result = {
            entries = Array.new(),
            xCenterOfMass = xCenter,
            xMinOffset = - xOffset,
            xMaxOffset = xOffset,
            weight = weight,
        }
        result.entries:pushBack(entryPos)
        setmetatable(result, Metatable)
        return result
    end,
}

-- Metatable of the LayerXPassBlock class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Appends an array of entries to this block.
        --
        -- The entries already present in the block won't be moved.
        --
        -- Args:
        -- * self: LayerXPassBlock object.
        -- * entryArray: Array of LayerEntryPosition to append to this block.
        --
        appendEntries = function(self, entryArray)
            local xMaxOffsetDelta = 0
            local entries = self.entries
            local baseCount = entries.count
            for i=1,entryArray.count do
                local newEntry = entryArray[i]
                entries[baseCount+i] = newEntry
                xMaxOffsetDelta = xMaxOffsetDelta + newEntry.output:getXLength(true)
            end
            entries.count = baseCount + entryArray.count
            self.xMaxOffset = self.xMaxOffset + xMaxOffsetDelta
        end,

        -- Uses the coordinates of this block to overwrite the X coordinates of its entries.
        --
        -- Args:
        -- * self: LayerXPassBlock object.
        --
        apply = function(self)
            local entries = self.entries
            local x = self.xMinOffset + self.xCenterOfMass
            for i=1,entries.count do
                local entryPos = entries[i]
                local node = entryPos.output
                local xMargin = node.xMargin
                local xLength = node:getXLength(false)
                x = x + xMargin
                entryPos:setXMin(x)
                x = x + xLength + xMargin
            end
        end,

        -- Append the given block to the current block.
        --
        -- Args:
        -- * self: LayerXPassBlock object.
        -- * nextBlock: Other LayerXPassBlock object to append to `self`.
        --
        mergeWith = function(self, nextBlock)
            local entries = self.entries
            mergeArrays(entries, nextBlock.entries)

            local weight = self.weight
            local nWeight = nextBlock.weight
            local totalWeight = weight + nWeight
            local center = self.xCenterOfMass
            local nCenter = nextBlock.xCenterOfMass
            local centerDist = self.xMaxOffset - nextBlock.xMinOffset
            self.xCenterOfMass = (weight * center + nWeight * nCenter) / totalWeight
            self.xMinOffset = self.xMinOffset - nWeight / totalWeight * centerDist
            self.xMaxOffset = nextBlock.xMaxOffset + weight / totalWeight * centerDist
            self.weight = totalWeight
        end,

        -- Prepents an array of entries to this block.
        --
        -- The entries already present in the block won't be moved.
        --
        -- The array passed in argument will be used by the block, so it can't be used anymore by the caller.
        --
        -- Args:
        -- * self: LayerXPassBlock object.
        -- * entryArray: Array containing the entries to prepend. It will be used by the block.
        --
        -- Returns: The old array of entries.
        --
        prependEntries = function(self, entryArray)
            local oldEntries = self.entries
            local xMinOffsetDelta = 0
            for i=1,entryArray.count do
                local entry = entryArray[i]
                xMinOffsetDelta = xMinOffsetDelta + entry.output:getXLength(true)
            end

            mergeArrays(entryArray, oldEntries)
            self.entries = entryArray
            self.xMinOffset = self.xMinOffset - xMinOffsetDelta

            return oldEntries
        end,
    }
}

-- Merges the second array into the first one.
--
-- Args:
-- * array1: The modified Array.
-- * array2: The Array to append to `array1`.
--
mergeArrays = function(array1, array2)
    local count1 = array1.count
    local count2 = array2.count
    for i=1,count2 do
        array1[count1+i] = array2[i]
    end
    array1.count = count1 +  count2
end

return LayerXPassBlock
