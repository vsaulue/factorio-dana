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
local AllQueryFilter = require("lua/model/query/filter/AllQueryFilter")
local Array = require("lua/containers/Array")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local QueryOrderer = require("lua/model/query/QueryOrderer")
local QuerySelector = require("lua/model/query/QuerySelector")

local Metatable

-- Class used to generate customized hypergraphs from a Force database.
--
-- RO Fields:
-- * filter: AbstractQueryFilter object, selecting the edges of the output graph.
-- * orderer: QueryOrderer object, generating a partial order used by the layout.
-- * selector: QuerySelector object, generating graph edges from the Force database.
--
local Query = ErrorOnInvalidRead.new{
    -- Creates a new Query object.
    --
    -- Returns: The new Query object.
    --
    new = function()
        local result = {
            filter = AllQueryFilter.new(),
            orderer = QueryOrderer.new(),
            selector = QuerySelector.new(),
        }
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a Query object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        AbstractQueryFilter.Factory:restoreMetatable(object.filter)
        QueryOrderer.setmetatable(object.orderer)
        QuerySelector.setmetatable(object.selector)
    end,
}

-- Metatable of the Query class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Executes this query on the specified database.
        --
        -- Args:
        -- * self: Query object.
        -- * force: Force database on which the query will be run.
        --
        -- Returns:
        -- * A DirectedHypergraph object holding the selected transforms & intermediates.
        -- * A map[vertexIndex] -> int. This is a suggested partial order of vertices. Those intermediates are the
        --   closest to the raw resources gathered, and can be used by the layout to display transform cycles in a
        --   way that'll (hopefully) make sense to the viewer.
        --
        execute = function(self, force)
            local fullGraph = self.selector:makeHypergraph(force)
            local vertexDists = self.orderer:makeOrder(force, fullGraph)

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

return Query
