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

local makeEdge
local Metatable

-- Class generating edges from the different transforms of a Force database.
--
-- In a standard SQL query, this object would correspond to:
-- SELECT a.x, a.y, b.x FROM a,b
--
-- Said in another way, this object:
-- * chooses which transforms (recipe, boiler, mining) will be turned into an edge.
-- * which transform properties will be turned into edge inputs & outputs (ex: mining fluid).
--
local QuerySelector = ErrorOnInvalidRead.new{
    -- Creates a new QuerySelector object.
    --
    -- Returns: The new QuerySelector object.
    --
    new = function()
        local result = {}
        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a QuerySelector object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the QuerySelector class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a DirectedHypergraph from a Force database.
        --
        -- Args:
        -- * self: QuerySelector object.
        -- * force: Force object on which this query will be run.
        --
        -- Returns: a DirectedHypergraph (vertices: intermediates & edges: transforms).
        --
        makeHypergraph = function(self, force)
            local result = DirectedHypergraph.new()

            for _,forceRecipe in pairs(force.recipes) do
                result:addEdge(makeEdge(forceRecipe.recipeTransform))
            end
            for _,boiler in pairs(force.prototypes.transforms.boiler) do
                result:addEdge(makeEdge(boiler))
            end

            return result
        end,
    },
}

-- Turns an entry from a PrototypeDatabase into a DirectedHypergraph edge.
--
-- Args:
-- * entry: An entry from PrototypeDatabase (supported types: recipe, boiler)
--
-- Returns: the new edge.
--
makeEdge = function(entry)
    return DirectedHypergraphEdge.new{
        index = entry,
        inbound = entry.ingredients,
        outbound = entry.products,
    }
end

return QuerySelector