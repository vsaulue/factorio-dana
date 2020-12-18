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

-- Class used to generate a partial order of the vertices returned by a query.
--
local OrderingStep = ErrorOnInvalidRead.new{
    -- Generates a partial order of all vertices.
    --
    -- Currently this order is always generated from the raw resources.
    --
    -- Args:
    -- * query: AbstractQuery. Parameters to use.
    -- * force: Force. Database on which this query will be run.
    -- * graph: DirectedHypergraph. Graph containing the vertices to order.
    --
    -- returns: Map[vertexIndex] -> int. Depth score (starting at 0) inducing a partial order of vertices.
    --
    run = function(query, force, graph)
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
}

return OrderingStep
