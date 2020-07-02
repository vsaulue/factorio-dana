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
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "AbstractQueryFilter"}

-- Class used to select specific transforms (as hypergraph edges) in a Query.
--
-- RO Fields:
-- * filterType: String encoding the exact subtype of this filter.
--
-- Abstract methods: see Metatable.__index.
--
local AbstractQueryFilter = ErrorOnInvalidRead.new{
    -- Factory object able to restore metatables of AbstractQueryFilter instances.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.filterType
        end,
    },

    -- Creates a new AbstractQueryFilter object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractQueryFilter object.
    -- * metatable: Metatable to set.
    --
    -- Returns: The argument turned into an AbstractQueryFilter object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "filterType")
        setmetatable(object, metatable)
        cLogger:assertField(object, "execute")
        return object
    end,
}

--[[
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Runs this filter on a specific edge set.
        --
        -- Args:
        -- * self: AbstractQueryFilter object.
        -- * edgeSet: Input set of DirectedHyperGraphEdge.
        --
        -- Returns: A new set containing the edges selected by this filter.
        --
        execute = function(self, edgeSet) end,
    }
}
]]

return AbstractQueryFilter
