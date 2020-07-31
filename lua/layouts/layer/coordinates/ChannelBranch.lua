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
local TreeLinkNode = require("lua/layouts/TreeLinkNode")

-- Class representing a branch of a trunk in a Channel routing algorithm.
--
-- * channelIndex: LinkIndex identifying the linked trunk and slot.
-- * entryNode: Tree node attached to the entry.
-- * entryPosition: LayerEntryPosition object.
-- * isLow: True if the entry is in the lower entry layer, false otherwise.
-- * trunkNode: Tree node attached to the trunk.
--
local ChannelBranch = ErrorOnInvalidRead.new{
    -- Turns a table into a ChannelBranch object.
    --
    -- Args:
    -- * object: Table to turn into a ChannelBranch object (must have the channelIndex, entryPosition, and isLow fields).
    --
    -- Returns: The argument, as a ChannelBranch object.
    --
    new = function(object)
        local channelIndex = object.channelIndex
        local entryPos = object.entryPosition
        local isLow = object.isLow
        assert(channelIndex, "ChannelBranch: missing mandatory 'channelIndex' field.")
        assert(entryPos, "ChannelBranch: missing mandatory 'entryPosition' field.")
        assert(isLow ~= nil, "ChannelBranch: missing mandatory 'isLow' field.")

        local isInbound = not isLow
        local entryNode = entryPos:getNode(channelIndex, isInbound)
        local x = entryNode.x
        ErrorOnInvalidRead.setmetatable(object)
        object.entryNode = entryNode
        object.trunkNode = TreeLinkNode.new{
            x = x,
        }
        object.x = x

        return object
    end,
}

return ChannelBranch
