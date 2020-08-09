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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "PrepNode"}

-- Node of a PrepGraph object.
--
-- RO Fields:
-- * index: Unique index of this node in a PrepGraph.
-- * inboundSlots: set of PrepLinkNode, representing the inputs of this node.
-- * orderPriority: int. Hint for placing order in layouts (lower == higher priority, starts at 1).
-- * outboundSlots: set of PrepLinkNode, representing the outputs of this node.
--
local PrepNode = ErrorOnInvalidRead.new{
    -- Creates a new PrepNode object.
    --
    -- Args:
    -- * object: Table to turn into a PrepNode object (required field: index).
    --
    -- Returns: The argument turned into a PrepNode object.
    --
    new = function(object)
        cLogger:assertField(object, "index")
        object.inboundSlots = ErrorOnInvalidRead.new()
        object.orderPriority = object.orderPriority or 1
        object.outboundSlots = ErrorOnInvalidRead.new()
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,
}

return PrepNode
