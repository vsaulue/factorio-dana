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

local AbstractFactory = require("lua/AbstractFactory")
local AbstractQueryFilter = require("lua/model/query/filter/AbstractQueryFilter")
local AllQueryFilter = require("lua/model/query/filter/AllQueryFilter")
local Array = require("lua/containers/Array")
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local QueryOrderer = require("lua/model/query/QueryOrderer")
local QuerySelector = require("lua/model/query/QuerySelector")

local cLogger = ClassLogger.new{className = "AbstractQuery"}

local Metatable

-- Class used to generate customized hypergraphs from a Force database.
--
-- RO Fields:
-- * filter: AbstractQueryFilter object, selecting the edges of the output graph.
-- * queryType: String encoding the exact subtype of this query.
--
local AbstractQuery = ErrorOnInvalidRead.new{
    -- Factory object able to restore metatables of AbstractQuery instances.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.queryType
        end,
    },

    -- Creates a new AbstractQuery object.
    --
    -- Args:
    -- * object: Table to turn into a AbstractQuery object (required fields: filter,queryType).
    -- * metatable: Metatable to set.
    --
    -- Returns: The new AbstractQuery object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "filter")
        cLogger:assertField(object, "queryType")
        setmetatable(object, metatable or Metatable)
        return object
    end,

    -- Restores the metatable of a AbstractQuery object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    -- * metatable: Metatable to set.
    --
    setmetatable = function(object, metatable)
        setmetatable(object, metatable or Metatable)
        AbstractQueryFilter.Factory:restoreMetatable(object.filter)
    end,
}

-- Metatable of the AbstractQuery class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Executes this query on the specified database.
        --
        -- Args:
        -- * self: AbstractQuery object.
        -- * force: Force database on which the query will be run.
        --
        -- Returns:
        -- * A DirectedHypergraph object holding the selected transforms & intermediates.
        -- * A map[vertexIndex] -> int. This is a suggested partial order of vertices. Those intermediates are the
        --   closest to the raw resources gathered, and can be used by the layout to display transform cycles in a
        --   way that'll (hopefully) make sense to the viewer.
        --
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

return AbstractQuery