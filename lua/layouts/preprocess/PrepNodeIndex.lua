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

local cLogger = ClassLogger.new{className = "PrepNodeIndex"}

local ValidTypes

-- Node index of a PrepGraph.
--
-- RO Fields:
-- * type: String representing the type of node.
--
local PrepNodeIndex = ErrorOnInvalidRead.new{
    -- Creates a new PrepNodeIndex.
    --
    -- Args:
    -- * object: Table to turn into a PrepNodeIndex object (required field: type).
    --
    -- Returns: The argument turned into a PrepNodeIndex object.
    --
    new = function(object)
        local type = cLogger:assertField(object, "type")
        cLogger:assert(ValidTypes[type], "Invalid PrepNode index type.")
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- -- Restores the metatable of a PrepNodeIndex object, and all its owned objects.
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

-- Set of valid values for the `type` field.
ValidTypes = {
    -- PrepNode wrapping a single edge of an hypergraph.
    hyperEdge = true,
    -- PrepNode wrapping a single vertex and its unique inbound edge in an hypergraph.
    hyperOneToOne = true,
    -- PrepNode wrapping a single vertex of an hypergraph.
    hyperVertex = true,
}

return PrepNodeIndex
