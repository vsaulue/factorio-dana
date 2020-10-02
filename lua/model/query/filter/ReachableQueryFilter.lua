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
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperMinDist = require("lua/hypergraph/algorithms/HyperMinDist")

local cLogger = ClassLogger.new{className = "ReachableQueryFilter"}

local FilterTypeName

-- Filters recursively selecting the transforms reachable from a given set of Intermediate.
--
-- This filter can either look for what can be produced from the set of Intermediate (forward parsing),
-- or look for transforms producing any element in the set (backward parsing).
--
-- Fields:
-- * allowOtherIntermediates: boolean to include transforms that use other intermediates.
-- * intermediateSet: Set of Intermediate, whose products must be selected.
-- * maxDepth (optional): Maximum depth for the breadth-first search (default: unlimited).
--
local ReachableQueryFilter = ErrorOnInvalidRead.new{
    -- Creates a new ReachableQueryFilter object.
    --
    -- Args:
    -- * object: Table to turn into a ReachableQueryFilter object.
    --
    -- Returns: The argument turned into a ReachableQueryFilter object.
    --
    new = function(object)
        object.allowOtherIntermediates = object.allowOtherIntermediates or false
        object.intermediateSet = object.intermediateSet or {}
        object.filterType = FilterTypeName
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of a ReachableQueryFilter object.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

-- Identifier for this type of filter.
FilterTypeName = "reachable"

return ReachableQueryFilter
