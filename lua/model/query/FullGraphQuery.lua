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

local AllQueryFilter = require("lua/model/query/filter/AllQueryFilter")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Query = require("lua/model/query/Query")

local QueryType

-- Query generating the full crafting graph.
--
local FullGraphQuery = ErrorOnInvalidRead.new{
    -- Creates a new FullGraphQuery object.
    --
    -- Returns: The new FullGraphQuery object.
    --
    new = function()
        local result = Query.new()
        result.filter = AllQueryFilter.new()
        result.queryType = QueryType
        return result
    end,

    -- Restores the metatable of a Query object, and all its owned objects.
    setmetatable = Query.setmetatable,
}

-- Identifier for this subtype of Query.
QueryType = "FullGraphQuery"

Query.Factory:registerClass(QueryType, FullGraphQuery)
return FullGraphQuery
