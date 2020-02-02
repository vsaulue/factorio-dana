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
local ReversibleArray = require("lua/containers/ReversibleArray")

-- Class for representing an entry (node) in a Layers object.
--
-- RO properties:
-- * type: must be either "edge", "linkNode", or "vertex".
-- * index: an identifier.
-- * inboundSlots: ReversibleArray containing the set of inbound ChannelIndex objects.
-- * outboundSlots: ReversibleArray containing the set of outbound ChannelIndex objects.
--
-- Additional fields for "linkNode" type:
-- * isForward: true if the link of this entry are going from lower to higher layer indices.
--
local LayerEntry = {
    new = nil,
}

local Impl = {
    ValidTypes = {
        edge = true,
        linkNode = true,
        vertex = true,
    }
}

-- Creates a new LayerEntry object.
--
-- Args:
-- * object: Table to turn into a LayerEntry (must have index & type fields).
--
-- Returns: The `object` argument, turned into a LayerEntry object.
--
function LayerEntry.new(object)
    assert(Impl.ValidTypes[object.type], "LayerEntry: invalid type.")
    assert(object.index, "LayerEntry: invalid index.")
    object.inboundSlots = ReversibleArray.new()
    object.outboundSlots = ReversibleArray.new()
    ErrorOnInvalidRead.setmetatable(object)
    return object
end

return LayerEntry
