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

local AbstractQueryFilter = require("lua/model/query/filter/AbstractQueryFilter")
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperMinDist = require("lua/hypergraph/algorithms/HyperMinDist")

local cLogger = ClassLogger.new{className = "ReachableQueryFilter"}

local Metatable
local FilterTypeName

-- Filters recursively selecting the transforms reachable from a given set of Intermediate.
--
-- This filter can either look for what can be produced from the set of Intermediate (forward parsing),
-- or look for transforms producing any element in the set (backward parsing).
--
-- Inherits from AbstractQueryFilter.
--
-- Fields:
-- * allowOtherIntermediates: boolean to include transforms that use other intermediates.
-- * intermediateSet: Set of Intermediate, whose products must be selected.
-- * isForward: True for forward parsing (select recipes that can be produced from the set).
--              False for backward parsing (select recipes that produces elements from the set).
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
        cLogger:assertField(object, "isForward")
        object.allowOtherIntermediates = object.allowOtherIntermediates or false
        object.intermediateSet = object.intermediateSet or {}
        object.filterType = FilterTypeName
        return AbstractQueryFilter.new(object, Metatable)
    end,

    -- Restores the metatable of a ReachableQueryFilter object.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the ReachableQueryFilter type.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractQueryFilter:execute().
        execute = function(self, edgeSet)
            local graph = DirectedHypergraph.new()
            for edge in pairs(edgeSet) do
                graph:addEdge(edge)
            end

            local distFunction
            if self.isForward then
                distFunction = HyperMinDist.fromSource
            else
                distFunction = HyperMinDist.toDest
            end

            local maxDepth = rawget(self, "maxDepth")
            local _,edgeDists = distFunction(graph, self.intermediateSet, self.allowOtherIntermediates, maxDepth)
            local result = {}
            for edgeIndex in pairs(edgeDists) do
                result[graph.edges[edgeIndex]] = true
            end
            return result
        end,
    },
}

-- Identifier for this subtype of AbstractQueryFilter.
FilterTypeName = "reachable"

AbstractQueryFilter.Factory:registerClass(FilterTypeName, ReachableQueryFilter)
return ReachableQueryFilter
