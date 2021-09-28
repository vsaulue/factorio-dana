-- This file is part of Dana.
-- Copyright (C) 2019-2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
        local filterSinkType = ErrorOnInvalidRead.new{
            none = false,
            normal = query.sinkParams.filterNormal,
            recursive = query.sinkParams.filterRecursive,
        }

        local addTransform = function(transform)
            if not filterSinkType[transform:getSinkType()] then
                result:addEdge(DirectedHypergraphEdge.new{
                    index = transform,
                    inbound = transform.ingredients,
                    outbound = transform.products,
                })
            end
        end

        if query.selectionParams.enableRecipes then
            for _,forceRecipe in pairs(force.recipes) do
                addTransform(forceRecipe.recipeTransform)
            end
        end
        if query.selectionParams.enableBoilers then
            for _,boiler in pairs(force.prototypes.transforms.boiler) do
                addTransform(boiler)
            end
        end
        if query.selectionParams.enableFuels then
            for _,fuel in pairs(force.prototypes.transforms.fuel) do
                addTransform(fuel)
            end
        end
        if query.selectionParams.enableResearches then
            for _,research in pairs(force.prototypes.transforms.research) do
                addTransform(research)
            end
        end

        return result
    end,
}

return SelectionStep
