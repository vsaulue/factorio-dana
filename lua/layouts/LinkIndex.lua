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

local cLogger = ClassLogger.new{className = "LinkIndex"}

-- Class implementing a unique key for links in layouts.
--
-- RO Fields:
-- * isFromVertexToEdge: true if the link is going from a vertex to an edge, false otherwise.
-- * vertexIndex: Unique identifier of a vertex in an hypergraph.
--
local LinkIndex = ErrorOnInvalidRead.new{
    -- Creates a new LinkIndex object.
    --
    -- Args:
    -- * object: Table to turn into a LinkIndex object (required fields: vertexIndex, isFromVertexToEdge).
    --
    -- Returns: The argument turned into a LinkIndex object.
    --
    new = function(object)
        cLogger:assertField(object, "vertexIndex")
        cLogger:assertField(object, "isFromVertexToEdge")
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    setmetatable = ErrorOnInvalidRead.setmetatable,
}

return LinkIndex
