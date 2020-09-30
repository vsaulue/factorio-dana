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

local AbstractQuery = require("lua/model/query/AbstractQuery")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ReachableQueryFilter = require("lua/model/query/filter/ReachableQueryFilter")
local QueryOrderer = require("lua/model/query/QueryOrderer")
local QuerySelector = require("lua/model/query/QuerySelector")

local Metatable
local QueryType

-- Query generating a subgraph showing what can be crafted from some intermediates.
--
local UsagesOfQuery = ErrorOnInvalidRead.new{
    -- Creates a new UsagesOfQuery object.
    --
    -- Returns: The new UsagesOfQuery object.
    --
    new = function()
        return AbstractQuery.new({
            filter = ReachableQueryFilter.new{
                isForward = true,
            },
            queryType = QueryType,
        }, Metatable)
    end,

    -- Restores the metatable of a UsagesOfQuery object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        ReachableQueryFilter.setmetatable(object.filter)
    end,
}

-- Metatable of the UsagesOfQuery class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractQuery:execute().
        execute = function(self, force)
            local selector = QuerySelector.new()
            local fullGraph = selector:makeHypergraph(force)

            local orderer = QueryOrderer.new()
            local vertexDists = orderer:makeOrder(force, fullGraph)

            local fullEdgeSet = {}
            for _,edge in pairs(fullGraph.edges) do
                fullEdgeSet[edge] = true
            end
            local filteredEdgeSet = self.filter:execute(fullEdgeSet)
            local resultGraph = DirectedHypergraph.new()
            for edge in pairs(filteredEdgeSet) do
                resultGraph:addEdge(edge)
            end

            return resultGraph,vertexDists
        end,
    },
}

-- Identifier for this subtype of AbstractQuery.
QueryType = "UsagesOfQuery"

AbstractQuery.Factory:registerClass(QueryType, UsagesOfQuery)
return UsagesOfQuery
