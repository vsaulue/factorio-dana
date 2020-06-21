-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local HyperSrcMinDist = require("lua/hypergraph/algorithms/HyperSrcMinDist")

local Metatable

-- Class used to generate a partial order of the vertices returned by a query.
--
-- In a SQL query, the closest equivalent would be:
-- ORDER BY **
--
-- A notable difference is that the generated order is partial, and some elements might not be included at
-- all in the order.
--
local QueryOrderer = ErrorOnInvalidRead.new{
    -- Creates a new QueryOrderer object.
    --
    -- Returns: The new QueryOrderer object.
    --
    new = function()
        local result = {}
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a QueryOrderer object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the QueryOrderer class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a partial order of all vertices.
        --
        -- Currently this order is always generated from the raw resources.
        --
        -- Args:
        -- * self: QueryOrderer object.
        -- * force: Force object on which this query will be run.
        -- * graph: DirectedHypergraph containing the vertices to order.
        --
        -- returns: A map[vertexIndex] -> int (starting at 0).
        --
        makeOrder = function(self, force, graph)
            local sourceSet = ErrorOnInvalidRead.new()

            for _,resource in pairs(force.prototypes.transforms.resource) do
                for product in pairs(resource.products) do
                    sourceSet[product] = true
                end
            end
            for _,offshorePump in pairs(force.prototypes.transforms.offshorePump) do
                for product in pairs(offshorePump.products) do
                    sourceSet[product] = true
                end
            end

            return HyperSrcMinDist.run(graph, sourceSet)
        end,
    },
}

return QueryOrderer
