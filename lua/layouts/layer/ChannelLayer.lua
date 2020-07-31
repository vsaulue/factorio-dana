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
local ReversibleArray = require("lua/containers/ReversibleArray")

local initChannel
local Metatable

-- Class holding the connection data between two layers in a LayersLayout object.
--
-- RO fields:
-- * highEntries[linkIndex]: ReversibleArray of entries from the upper layer connected to a channel.
--   (ordered from lower to higher rank in the entry layer)
-- * lowEntries[linkIndex]: ReversibleArray of entries from the lower layer connected to a channel.
--   (ordered from lower to higher rank in the entry layer)
--
-- Methods: see Metatable.__index.
--
local ChannelLayer = ErrorOnInvalidRead.new{
    -- Creates a new empty ChannelLayer object.
    --
    -- Returns: the new ChannelLayer object.
    --
    new = function()
        local result = ErrorOnInvalidRead.new{
            highEntries = ErrorOnInvalidRead.new(),
            lowEntries = ErrorOnInvalidRead.new(),
        }
        setmetatable(result, Metatable)
        return result
    end,
}


-- Initializes a channel (or does nothing if the channel already exists).
--
-- Args:
-- * self: ChannelLayer object.
-- * channelIndex: LinkIndex corresponding to the channel to initialize.
--
initChannel = function(self, channelIndex)
    if not rawget(self.lowEntries, channelIndex) then
        self.highEntries[channelIndex] = ReversibleArray.new()
        self.lowEntries[channelIndex] = ReversibleArray.new()
    end
end

-- Metatatble of the ChannelLayer class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds an entry from the higher layer to the given channel.
        --
        -- Automatically creates the appropriate channel if it doesn't exist yet.
        --
        -- Args:
        -- * self: ChannelLayer object.
        -- * channelIndex: LinkIndex corresponding to the channel to edit.
        -- * highEntry: Entry of the next layer to append to this channel's connections
        --
        appendHighEntry = function(self, channelIndex, highEntry)
            initChannel(self, channelIndex)
            self.highEntries[channelIndex]:pushBackIfNotPresent(highEntry)
        end,

        -- Adds an entry from the lower layer to the given channel.
        --
        -- Automatically creates the appropriate channel if it doesn't exist yet.
        --
        -- Args:
        -- * self: ChannelLayer object.
        -- * channelIndex: LinkIndex corresponding to channel to edit.
        -- * lowEntry: Entry of the previous layer to append to this channel's connections
        --
        appendLowEntry = function(self, channelIndex, lowEntry)
            initChannel(self, channelIndex)
            self.lowEntries[channelIndex]:pushBackIfNotPresent(lowEntry)
        end,
    },
}

return ChannelLayer
