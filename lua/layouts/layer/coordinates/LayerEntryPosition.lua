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

-- Class holding placement data of a specific entry.
--
--  Fields:
--   * output: placement data of this entry, returned in the LayoutCoordinates object.
--   * inboundNodes[channelIndex]: Tree node of the given channel index for inbound slots.
--   * outboundNodes[channelIndex]: Tree node of the given channel index for outbound slots.
--   * inboundOffsets[channelIndex]: x-offset of the given inbound slot.
--   * outboundOffsets[channelIndex]: x-offset of the given outbound slot.
--
-- Methods:
-- * getSlotAbsoluteX: Gets the absolute X coordinate of a slot.
-- * initX: Initializes the X coordinates of this object.
-- * translateX: Moves this object on the X axis.
--
local LayerEntryPosition = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local fillSlotOffsets

-- Map giving the field name for slot offsets.
local offsetsFieldName = ErrorOnInvalidRead.new{
    [true] = "inboundOffsets",
    [false] = "outboundOffsets",
}

-- Metatable of the LayerEntryPosition class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets the absolute X coordinate of a slot.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * channelIndex: Channel index of the slot.
        -- * isInbound: true for an inbound slot, false otherwise.
        --
        getSlotAbsoluteX = function(self, channelIndex, isInbound)
            local offset = self[offsetsFieldName[isInbound]][channelIndex]
            return self.output.xMin + offset
        end,
        -- Initializes the X coordinates of this object.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * xMin: New xMin value.
        -- * xLength: New length of this object on the X-axis.
        --
        initX = function(self, xMin, xLength)
            local entry = self.entry
            self.output.xMin = xMin
            self.output.xMax = xMin + xLength
            fillSlotOffsets(entry.inboundSlots, self.inboundOffsets, xLength)
            fillSlotOffsets(entry.outboundSlots, self.outboundOffsets, xLength)
        end,

        -- Moves this object on the X axis.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * xDelta: Value to add to the X coordinates.
        --
        translateX = function(self, xDelta)
            local output = self.output
            output.xMin = output.xMin + xDelta
            output.xMax = output.xMax + xDelta
        end,
    },
}

-- Fills the inboundOffsets & outboundOffsets fields of a LayerEntryPosition object.
--
-- Args:
-- * slots: ReversibleArray of slots (ex: LayerEntry.inboundSlots).
-- * output: Table in which the offsets should be written.
-- * xLength: Length of the entry.
--
fillSlotOffsets = function(slots, output, xLength)
    local count = slots.count
    for rank=1,count do
        local channelIndex = slots[rank]
        output[channelIndex] = xLength * (rank - 0.5) / count
    end
end

-- Turns a table into a LayerEntryPosition object.
--
-- Args:
-- * object: The table to turn into a LayerEntryPosition object. Must have an entry field.
--
-- Returns: object, turned into a LayerEntryPosition object.
--
function LayerEntryPosition.new(object)
    assert(object.entry, "LayerEntryPosition: missing mandatory 'entry' field.")

    object.output = ErrorOnInvalidRead.new()
    object.inboundNodes = ErrorOnInvalidRead.new()
    object.inboundOffsets = ErrorOnInvalidRead.new()
    object.outboundNodes = ErrorOnInvalidRead.new()
    object.outboundOffsets = ErrorOnInvalidRead.new()

    setmetatable(object, Metatable)
    return object
end

return LayerEntryPosition
