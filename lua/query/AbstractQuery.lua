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

local cLogger = ClassLogger.new{className = "AbstractQuery"}

-- Class used to generate customized hypergraphs from a Force database.
--
-- RO Fields:
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
    -- * object: Table to turn into a AbstractQuery object (required field: queryType).
    -- * metatable: Metatable to set.
    --
    -- Returns: The new AbstractQuery object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "queryType")
        setmetatable(object, metatable)
        return object
    end,
}

--[[
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
        execute = function(self, force) end,
    },
}
--]]

return AbstractQuery
