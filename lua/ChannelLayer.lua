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

local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")
local ReversibleArray = require("lua/ReversibleArray")

-- Class holding the connection data between two layers in a LayersLayout object.
--
-- RO fields:
-- * order: ReversibleArray containing all the channel indexes in this ChannelLayer object.
-- * highEntries[channelIndex]: ReversibleArray of entries from the upper layer connected to a channelIndex
--   (ordered from lower to higher rank in the entry layer)
-- * lowEntries[channelIndex]: ReversibleArray of entries from the lower layer connected to a channelIndex
--   (ordered from lower to higher rank in the entry layer)
--
-- Methods:
-- * appendHighEntry: Adds an entry from the higher layer to the given channel.
-- * appendLowEntry: Adds an entry from the lower layer to the given channel.
--
local ChannelLayer = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    -- Initializes a channel (or does nothing if the channel already exists).
    --
    -- Args:
    -- * self: ChannelLayer object.
    -- * channelIndex: Index of the channel to initialize.
    --
    initChannelIndex = function(self, channelIndex)
        if not rawget(self.order, channelIndex) then
            self.order:pushBack(channelIndex)
            self.highEntries[channelIndex] = ReversibleArray.new()
            self.lowEntries[channelIndex] = ReversibleArray.new()
        end
    end,

    -- Metatatble of the ChannelLayer class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            appendHighEntry = nil, -- implemented later

            appendLowEntry = nil, -- implemented later
        },
    },
}

-- Creates a new empty ChannelLayer object.
--
-- Returns: the new ChannelLayer object.
--
function ChannelLayer.new()
    local result = ErrorOnInvalidRead.new{
        order = ReversibleArray.new(),
        highEntries = ErrorOnInvalidRead.new(),
        lowEntries = ErrorOnInvalidRead.new(),
    }
    setmetatable(result, Impl.Metatable)
    return result
end

-- Adds an entry from the higher layer to the given channel.
--
-- Automatically creates the appropriate channel if it doesn't exist yet.
--
-- Args:
-- * self: ChannelLayer object.
-- * channelIndex: Index of the channel to initialize.
-- * highEntry: Entry of the next layer to append to this channel's connections
--
function Impl.Metatable.__index.appendHighEntry(self, channelIndex, highEntry)
    Impl.initChannelIndex(self, channelIndex)
    self.highEntries[channelIndex]:pushBackIfNotPresent(highEntry)
end

-- Adds an entry from the lower layer to the given channel.
--
-- Automatically creates the appropriate channel if it doesn't exist yet.
--
-- Args:
-- * self: ChannelLayer object.
-- * channelIndex: Index of the channel to initialize.
-- * lowEntry: Entry of the previous layer to append to this channel's connections
--
function Impl.Metatable.__index.appendLowEntry(self, channelIndex, lowEntry)
    Impl.initChannelIndex(self, channelIndex)
    self.lowEntries[channelIndex]:pushBackIfNotPresent(lowEntry)
end

return ChannelLayer
