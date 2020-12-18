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

local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local addTransform

-- Helper class to generate an hypergraph from a Force database.
--
local SelectionStep = ErrorOnInvalidRead.new{
    -- Generates an hypergraph from a specific database & query parameters.
    --
    -- This step generates an "almost" full graph. Only transforms that do not affect reachability
    -- or vertex order may be removed (ex: direct sinks).
    --
    -- Args:
    -- * query: AbstractQuery. Parameters to use.
    -- * force: Force. Database on which this query will be run.
    --
    -- Returns: DirectedHypergraph. A graph containing all pre-filtered transforms.
    --
    run = function(query, force)
        local result = DirectedHypergraph.new()

        for _,forceRecipe in pairs(force.recipes) do
            addTransform(query, result, forceRecipe.recipeTransform)
        end
        for _,boiler in pairs(force.prototypes.transforms.boiler) do
            addTransform(query, result, boiler)
        end
        for _,fuel in pairs(force.prototypes.transforms.fuel) do
            addTransform(query, result, fuel)
        end

        return result
    end,
}

-- Adds a transform as a graph edges if it matches the selector's parameters.
--
-- Args:
-- * query: AbstractQuery. Paremeters to use.
-- * graph: DirectedHypergraph. Graph to fill.
-- * transform: AbstractTransform. Transform to add.
--
addTransform = function(query, graph, transform)
    local products = transform.products
    if next(transform.products) then
        graph:addEdge(DirectedHypergraphEdge.new{
            index = transform,
            inbound = transform.ingredients,
            outbound = products,
        })
    end
end

return SelectionStep
