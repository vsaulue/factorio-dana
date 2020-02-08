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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Logger = require("lua/Logger")

-- Class representing a link in a LayersBuilder object.
--
-- RO fields:
-- * inbound: source LayerEntry.
-- * outbound: destination LayerEntry.
-- * channelIndex: ChannelIndex object, holding the vertexIndex & direction of this link.
--
-- Methods:
-- * getOtherEntry: get the other end of this link.
--
local LayerLink = {
    new = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the LayerLink class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Gets the other end of this link.
            --
            -- Args:
            -- * self: LayerLink object.
            -- * firstEntry: an end of `self`.
            --
            -- Returns: The end in `self` that is not `firstEntry`.
            --
            getOtherEntry = function(self, firstEntry)
                local result = nil
                if self.inbound == firstEntry then
                    result = self.outbound
                elseif self.outbound == firstEntry then
                    result = self.inbound
                else
                    Logger.error("LayerLink:getOtherEntry(): argument is not an entry of this link.")
                end
                return result
            end
        },
    },
}

-- Creates a new link.
--
-- Args:
-- * lowEntry: LayerEntry with the lowest layerId to link.
-- * highEntry: LayerEntry with the greatest layerId to link.
-- * channelIndex: ChannelIndex object, defining the vertexIndex & direction of this link.
--
function LayerLink.new(lowEntry, highEntry, channelIndex)
    assert(lowEntry)
    assert(highEntry)
    assert(channelIndex)
    local result = ErrorOnInvalidRead.new{
        channelIndex = channelIndex,
        inbound = lowEntry,
        outbound = highEntry,
    }
    if not channelIndex.isForward then
        result.inbound = highEntry
        result.outbound = lowEntry
    end
    setmetatable(result, Impl.Metatable)
    return result
end

return LayerLink
