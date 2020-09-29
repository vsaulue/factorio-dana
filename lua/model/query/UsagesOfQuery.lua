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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ReachableQueryFilter = require("lua/model/query/filter/ReachableQueryFilter")

local QueryType

-- Query generating a subgraph showing what can be crafted from some intermediates.
--
local UsagesOfQuery = ErrorOnInvalidRead.new{
    -- Creates a new UsagesOfQuery object.
    --
    -- Returns: The new UsagesOfQuery object.
    --
    new = function()
        return AbstractQuery.new{
            filter = ReachableQueryFilter.new{
                isForward = true,
            },
            queryType = QueryType,
        }
    end,

    -- Restores the metatable of a UsagesOfQuery object, and all its owned objects.
    setmetatable = AbstractQuery.setmetatable,
}

-- Identifier for this subtype of AbstractQuery.
QueryType = "UsagesOfQuery"

AbstractQuery.Factory:registerClass(QueryType, UsagesOfQuery)
return UsagesOfQuery
