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
local Tree = require("lua/containers/Tree")

-- Class holding placement data of a specific entry.
--
-- The X coordinate of slots are directly stored in their associated link node.
--
--  Fields:
--   * output: placement data of this entry, returned in the LayoutCoordinates object.
--   * inboundNodes[channelIndex]: Tree node of the given channel index for inbound slots.
--   * outboundNodes[channelIndex]: Tree node of the given channel index for outbound slots.
--
-- Methods:
-- * getNode: Gets the tree node associated to the given slot.
-- * initX: Initializes the X coordinates of this object.
-- * translateX: Moves this object on the X axis.
--
local LayerEntryPosition = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local buildNodes
local computeSlotsX
local setSlotsY
local translateNodesX

-- Map giving the field name for slot nodes.
local nodesFieldName = ErrorOnInvalidRead.new{
    [true] = "inboundNodes",
    [false] = "outboundNodes",
}

-- Metatable of the LayerEntryPosition class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets the tree node associated to the given slot.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * channelIndex: Channel index of the slot.
        -- * isInbound: true for an inbound slot, false otherwise.
        --
        -- Returns: The tree object associated to the given slot.
        --
        getNode = function(self, channelIndex, isInbound)
            return self[nodesFieldName[isInbound]][channelIndex]
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
            computeSlotsX(entry.inboundSlots, self.inboundNodes, xMin, xLength)
            computeSlotsX(entry.outboundSlots, self.outboundNodes, xMin, xLength)
        end,

        -- Initializes the Y coordinates of this object.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * yMin: New yMin value.
        -- * yMax: New yMax value.
        --
        initY = function(self, yMin, yMax)
            local entry = self.entry
            self.output.yMin = yMin
            self.output.yMax = yMax
            setSlotsY(self.inboundNodes, yMin)
            setSlotsY(self.outboundNodes, yMax)
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
            translateNodesX(self.inboundNodes, xDelta)
            translateNodesX(self.outboundNodes, xDelta)
        end,
    },
}

-- Builds a map of Tree nodes corresponding to a ReversibleArray of ChannelIndex.
--
-- Args:
-- * slots: ReversibleArray of ChannelIndex.
--
-- Returns: A map of Tree objects, indexed by channel indexes.
--
buildNodes = function(slots)
    local result = ErrorOnInvalidRead.new()
    for i=1,slots.count do
        local channelIndex = slots[i]
        result[channelIndex] = Tree.new()
    end
    return result
end

-- Fills x field of a set of link nodes.
--
-- Args:
-- * slots: ReversibleArray of slots (ex: LayerEntry.inboundSlots).
-- * nodes: Map of link nodes, indexed by channel indexes.
-- * xMin: New xMin value of the entry.
-- * xLength: Length of the entry.
--
computeSlotsX = function(slots, nodes, xMin, xLength)
    local count = slots.count
    for rank=1,count do
        local channelIndex = slots[rank]
        local node = nodes[channelIndex]
        node.x = xMin + xLength * (rank - 0.5) / count
    end
end

-- Sets the y field of a set of link nodes.
--
-- Args:
-- * nodes: Map of link nodes, indexed by channel indexes.
-- * y: New 'y' value of the nodes.
--
setSlotsY = function(nodes, y)
    for _,node in pairs(nodes) do
        node.y = y
    end
end

-- Updates the x field of a set of link nodes.
--
-- Args:
-- * nodes: Map of Tree nodes.
-- * xDelta: Value to add to the x field of tree nodes.
--
translateNodesX = function(nodes, xDelta)
    for _,node in pairs(nodes) do
        node.x = node.x + xDelta
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
    local entry = object.entry
    assert(entry, "LayerEntryPosition: missing mandatory 'entry' field.")

    object.output = ErrorOnInvalidRead.new()
    object.inboundNodes = buildNodes(entry.inboundSlots)
    object.outboundNodes = buildNodes(entry.outboundSlots)

    setmetatable(object, Metatable)
    return object
end

return LayerEntryPosition
