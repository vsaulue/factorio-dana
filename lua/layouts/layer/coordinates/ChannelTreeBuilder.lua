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
local Iterator = require("lua/containers/utils/Iterator")
local Tree = require("lua/containers/Tree")

-- Helper class to build the tree link of a specific channel.
--
-- Fields:
-- * channelIndex: Index of the channel to build.
-- * entryPositions: entryPositions field of the LayerCoordinateGenerator object running this builder.
-- * itHigh: Iterator object running on the high entries of the channel.
-- * itLow: Iterator object running on the low entries of the channel.
-- * output: Root of the tree being generated.
-- * xHigh: X coordinate of the slot for this channel in itHigh's entry.
-- * xLow: X coordinate of the slot for this channel in itLow's entry.
-- * y: Y coordinate of this channel.
--
local ChannelTreeBuilder = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    nextHigh = nil, -- implemented later

    nextLow = nil, -- implemented later

    updateTree = nil, -- implemented later
}

-- Creates the tree link of a specified channel.
--
-- The nodes attached to an entry will be properly added to the corresponding LayerEntryPosition
-- objects inside entryPositions. The Y field of these nodes are NOT set by this function.
--
-- Args:
-- * channelLayer: ChannelLayer object containing the channel.
-- * channelIndex: Index of the channel in `channelLayer`.
-- * entryPositions: LayerCoordinateGenerator.entryPositions field of the layout being computed.
-- * y: Y coordinate of the channel.
--
-- Returns: a Tree object representing this channel for a LayoutCoordinates object.
--
function ChannelTreeBuilder.run(channelLayer, channelIndex, entryPositions, y)
    local self = {
        entryPositions = entryPositions,
        channelIndex = channelIndex,
        itHigh = Iterator.new(channelLayer.highEntries[channelIndex]),
        itLow = Iterator.new(channelLayer.lowEntries[channelIndex]),
        output = nil,
        xHigh = nil,
        xLow = nil,
        y = y,
    }
    Impl.nextHigh(self)
    Impl.nextLow(self)
    while self.itHigh.value and self.itLow.value do
        if self.xHigh < self.xLow then
            Impl.nextHigh(self)
        else
            Impl.nextLow(self)
        end
    end
    while self.itHigh.value do
        Impl.nextHigh(self)
    end
    while self.itLow.value do
        Impl.nextLow(self)
    end
    return self.output
end

-- Connects a new entry to the tree.
--
-- Args:
-- * self: ChannelTreeBuilder object.
-- * x: X coordinate of the entry's slot to connect.
-- * nodes: Map in which to add the tree node connected to the entry to connect.
--
function Impl.updateTree(self, x, nodes)
    local newRoot = Tree.new{
        x = x,
        y = self.y,
    }
    local entryTreeNode = Tree.new{
        x = x,
    }
    nodes[self.channelIndex] = entryTreeNode
    newRoot:addChild(entryTreeNode)
    if self.output then
        newRoot:addChild(self.output)
    end
    self.output = newRoot
end

-- Add the current high entry to the channel, then update itHigh and xHigh.
--
-- Args:
-- * self: ChannelTreeBuilder object.
--
function Impl.nextHigh(self)
    local itHigh = self.itHigh
    if itHigh.value then
        local entry = itHigh.value
        local nodes = self.entryPositions[entry].inboundNodes
        Impl.updateTree(self, self.xHigh, nodes)
    end
    if itHigh:next() then
        local entry = itHigh.value
        local entryPosition = self.entryPositions[entry]
        self.xHigh = entryPosition.output.xMin + entryPosition.inboundOffsets[self.channelIndex]
    else
        self.xHigh = nil
    end
end

-- Add the current low entry to the channel, then update itLow and xLow.
--
-- Args:
-- * self: ChannelTreeBuilder object.
--
function Impl.nextLow(self)
    local itLow = self.itLow
    if itLow.value then
        local entry = itLow.value
        local nodes = self.entryPositions[entry].outboundNodes
        Impl.updateTree(self, self.xLow, nodes)
    end
    if itLow:next() then
        local entry = itLow.value
        local entryPosition = self.entryPositions[entry]
        self.xLow = entryPosition.output.xMin + entryPosition.outboundOffsets[self.channelIndex]
    else
        self.xLow = nil
    end
end

return ChannelTreeBuilder
