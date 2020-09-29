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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Query = require("lua/model/query/Query")
local ReachableQueryFilter = require("lua/model/query/filter/ReachableQueryFilter")

local QueryType

-- Query generating a subgraph showing how to craft some given intermediates.
--
local HowToMakeQuery = ErrorOnInvalidRead.new{
    -- Creates a new HowToMakeQuery object.
    --
    -- Returns: The new HowToMakeQuery object.
    --
    new = function()
        local result = Query.new()
        result.filter = ReachableQueryFilter.new{
            isForward = false,
        }
        result.queryType = QueryType
        return result
    end,

    -- Restores the metatable of a HowToMakeQuery object, and all its owned objects.
    setmetatable = Query.setmetatable,
}

-- Identifier for this subtype of Query.
QueryType = "HowToMakeQuery"

Query.Factory:registerClass(QueryType, HowToMakeQuery)
return HowToMakeQuery
