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

-- Parameters used for a breadth-first search from/to specific vertices of the graph.
--
-- Fields:
-- * allowOtherIntermediates: boolean to include transforms that use other intermediates.
-- * intermediateSet: Set of Intermediate, whose products must be selected.
-- * maxDepth (optional): Maximum depth for the breadth-first search (default: unlimited).
--
local MinDistParams = ErrorOnInvalidRead.new{
    -- Creates a new MinDistParams object.
    --
    -- Args:
    -- * object: Table to turn into a MinDistParams object.
    --
    -- Returns: The argument turned into a MinDistParams object.
    --
    new = function(object)
        object.allowOtherIntermediates = object.allowOtherIntermediates or false
        object.intermediateSet = object.intermediateSet or {}
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of a MinDistParams object.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

return MinDistParams
