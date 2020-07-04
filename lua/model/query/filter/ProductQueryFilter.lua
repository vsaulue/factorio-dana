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
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HyperMinDist = require("lua/hypergraph/algorithms/HyperMinDist")

local Metatable
local FilterTypeName

-- Filters recursively selecting the transforms consuming a given set of intermediates.
--
-- Inherits from AbstractQueryFilter.
--
-- Fields:
-- * allowOtherIngredients: boolean to include transforms that use other intermediates.
-- * maxDepth (optional): Maximum depth for the breadth-first search (default: unlimited).
-- * sourceIntermediates: Set of Intermediate, whose products must be selected.
--
local ProductQueryFilter = ErrorOnInvalidRead.new{
    -- Creates a new ProductQueryFilter object.
    --
    -- Args:
    -- * object: Table to turn into a ProductQueryFilter object.
    --
    -- Returns: The argument turned into a ProductQueryFilter object.
    --
    new = function(object)
        local result = object or {}
        result.allowOtherIngredients = result.allowOtherIngredients or false
        result.sourceIntermediates = result.sourceIntermediates or {}
        result.filterType = FilterTypeName
        return AbstractQueryFilter.new(result, Metatable)
    end,

    -- Restores the metatable of a ProductQueryFilter object.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the ProductQueryFilter type.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractQueryFilter:execute().
        execute = function(self, edgeSet)
            local graph = DirectedHypergraph.new()
            for edge in pairs(edgeSet) do
                graph:addEdge(edge)
            end

            local maxDepth = rawget(self, "maxDepth")
            local _,edgeDists = HyperMinDist.fromSource(graph, self.sourceIntermediates, self.allowOtherIngredients, maxDepth)
            local result = {}
            for edgeIndex in pairs(edgeDists) do
                result[graph.edges[edgeIndex]] = true
            end
            return result
        end,
    },
}

-- Identifier for this subtype of AbstractQueryFilter.
FilterTypeName = "product"

AbstractQueryFilter.Factory:registerClass(FilterTypeName, ProductQueryFilter)
return ProductQueryFilter
