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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local Metatable
local FilterTypeName

-- Query filter that forwards every edges.
--
-- Inherits from AbstractQueryFilter.
--
local AllQueryFilter = ErrorOnInvalidRead.new{
    -- Creates a new AllQueryFilter object.
    --
    -- Returns: The new AllQueryFilter object.
    --
    new = function()
        local result = {
            filterType = FilterTypeName,
        }
        AbstractQueryFilter.new(result, Metatable)
        return result
    end,

    -- Restores the metatable of an AllQueryFilter object.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the AllQueryFilter object.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractQueryFilter:execute().
        execute = function(self, edgeSet)
            return edgeSet
        end,
    }
}

-- Identifier for this subtype of AbstractQueryFilter.
FilterTypeName = "all"

AbstractQueryFilter.Factory:registerClass(FilterTypeName, AllQueryFilter)
return AllQueryFilter
