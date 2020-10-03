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
local Metatable

-- Helper class to generate an hypergraph from a Force database.
--
-- Fields:
-- * includeSinks: Boolean to include sink recipes.
--
local SelectionStep = ErrorOnInvalidRead.new{
    -- Creates a new SelectionStep object.
    --
    -- Returns: The new SelectionStep object.
    --
    new = function()
        local result = {
            includeSinks = false,
        }
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a SelectionStep object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the SelectionStep class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a DirectedHypergraph from a Force database.
        --
        -- Args:
        -- * self: SelectionStep object.
        -- * force: Force object on which this query will be run.
        --
        -- Returns: a DirectedHypergraph (vertices: intermediates & edges: transforms).
        --
        makeHypergraph = function(self, force)
            local result = DirectedHypergraph.new()

            for _,forceRecipe in pairs(force.recipes) do
                addTransform(self, result, forceRecipe.recipeTransform)
            end
            for _,boiler in pairs(force.prototypes.transforms.boiler) do
                addTransform(self, result, boiler)
            end
            for _,fuel in pairs(force.prototypes.transforms.fuel) do
                addTransform(self, result, fuel)
            end

            return result
        end,
    },
}

-- Adds a transform as a graph edges if it matches the selector's parameters.
--
-- Args:
-- * self: SelectionStep object.
-- * graph: DirectedHypergraph to fill.
-- * transform: AbstractTransform to add.
--
addTransform = function(self, graph, transform)
    local products = transform.products
    if self.includeSinks or next(transform.products) then
        graph:addEdge(DirectedHypergraphEdge.new{
            index = transform,
            inbound = transform.ingredients,
            outbound = products,
        })
    end
end

return SelectionStep
