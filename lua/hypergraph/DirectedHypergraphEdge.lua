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

local cLogger = ClassLogger.new{className = "DirectedHypergraphEdge"}

-- Edge in a DirectedHypergraph class.
--
-- Fields:
-- * index: string or table value acting as a unique identifier in a given graph.
-- * inbound: set of vertex indices, representing inputs of this edge
-- * outbound: set of vertex indices, representing outputs of this edge
--
local DirectedHypergraphEdge = ErrorOnInvalidRead.new{
    -- Creates a new DirectedHypergraphEdge object.
    --
    -- Args:
    -- * object: Table to turn into a DirectedHypergraphEdge object (required field: index).
    --
    -- Returns: The argument turned into a DirectedHypergraphEdge object.
    --
    new = function(object)
        cLogger:assertField(object, "index")
        object.inbound = object.inbound or {}
        object.outbound = object.outbound or {}
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of a DirectedHypergraphEdge object, and all its owned objects.
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

return DirectedHypergraphEdge
