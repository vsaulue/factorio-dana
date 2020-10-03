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
local HyperMinDist = require("lua/hypergraph/algorithms/HyperMinDist")

local Metatable

-- Class used to generate a partial order of the vertices returned by a query.
--
local OrderingStep = ErrorOnInvalidRead.new{
    -- Creates a new OrderingStep object.
    --
    -- Returns: The new OrderingStep object.
    --
    new = function()
        local result = {}
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a OrderingStep object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the OrderingStep class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a partial order of all vertices.
        --
        -- Currently this order is always generated from the raw resources.
        --
        -- Args:
        -- * self: OrderingStep object.
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

            return HyperMinDist.fromSource(graph, sourceSet, false)
        end,
    },
}

return OrderingStep
