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

local AbstractFactory = require("lua/class/AbstractFactory")
local Array = require("lua/containers/Array")
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local OrderingStep = require("lua/query/steps/OrderingStep")
local SelectionStep = require("lua/query/steps/SelectionStep")
local SinkFilterStep = require("lua/query/steps/SinkFilterStep")
local SinkParams = require("lua/query/params/SinkParams")

local cLogger = ClassLogger.new{className = "AbstractQuery"}
local new

-- Class used to generate customized hypergraphs from a Force database.
--
-- RO Fields:
-- * queryType: String encoding the exact subtype of this query.
-- * sinkParams: SinkParams. Parameters of the sink filter.
--
local AbstractQuery = ErrorOnInvalidRead.new{
    -- Creates a copy of this query.
    --
    -- Args:
    -- * self: AbstractQuery.
    -- * metatable: table. Metatable to set.
    --
    -- Returns: AbstractQuery. A copy of the `self` argument.
    --
    copy = function(self, metatable)
        return new({
            queryType = self.queryType,
            sinkParams = SinkParams.copy(self.sinkParams),
        }, metatable)
    end,

    -- Factory object able to restore metatables of AbstractQuery instances.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.queryType
        end,
    },

    -- Creates a new AbstractQuery object.
    --
    -- Args:
    -- * object: Table to turn into a AbstractQuery object (required field: queryType).
    -- * metatable: Metatable to set.
    --
    -- Returns: The new AbstractQuery object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "queryType")
        object.sinkParams = SinkParams.new(object.sinkParams)
        setmetatable(object, metatable)
        return object
    end,

    -- Generates the filtered graph and the vertex order from the abstract parameters.
    --
    -- Args:
    -- * self: AbstractQuery.
    -- * force: Force. Database on which the query will be run.
    --
    -- Returns:
    -- * DirectedHypergraph. Graph containing the selected transforms & intermediates after filtering.
    -- * Map[vertexIndex] -> int. Partial order on the vertices to build a "nicer" layout.
    --
    preprocess = function(self, force)
        local graph = SelectionStep.run(self, force)
        local vertexDists = OrderingStep.run(self, force, graph)
        SinkFilterStep.run(self, force, graph)
        return graph,vertexDists
    end,

    -- Restores the metatable of a AbstractQuery object, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object, metatable)
        setmetatable(object, metatable)
        SinkParams.setmetatable(object.sinkParams)
    end,
}

--[[
-- Metatable of the AbstractQuery class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Creates a copy of this query.
        --
        -- Args:
        -- * self: AbstractQuery.
        --
        -- Returns: AbstractQuery. An identical query.
        --
        copy = function(self) end,

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
        execute = function(self, force) end,
    },
}
--]]

new = AbstractQuery.new

return AbstractQuery
