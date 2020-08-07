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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ReversibleArray = require("lua/containers/ReversibleArray")

local cLogger = ClassLogger.new{className = "LayerEntry"}

local ValidTypes

-- Class for representing an entry (node) in a Layers object.
--
-- RO properties:
-- * type: must be either "linkNode" or "node".
-- * index: an identifier.
-- * lowSlots: ReversibleArray containing the set of low LayerLinkIndex objects.
-- * highSlots: ReversibleArray containing the set of high LayerLinkIndex objects.
--
-- Additional fields for "linkNode" type:
-- * isForward: true if the link of this entry are going from lower to higher layer indices.
--
local LayerEntry = ErrorOnInvalidRead.new{
    -- Creates a new LayerEntry object.
    --
    -- Args:
    -- * object: Table to turn into a LayerEntry (must have index & type fields).
    --
    -- Returns: The `object` argument, turned into a LayerEntry object.
    --
    new = function(object)
        cLogger:assertField(object, "index")
        local type = cLogger:assertField(object, "type")
        cLogger:assert(ValidTypes[type], "invalid type.")
        object.lowSlots = ReversibleArray.new()
        object.highSlots = ReversibleArray.new()
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,
}

-- Set of valid values for the "type" field.
ValidTypes = {
    linkNode = true,
    node = true,
}

return LayerEntry
