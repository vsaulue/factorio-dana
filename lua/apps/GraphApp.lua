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

local Canvas = require("lua/canvas/Canvas")
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayerLayout = require("lua/layouts/layer/LayerLayout")
local SimpleRenderer = require("lua/SimpleRenderer")

local cLogger = ClassLogger.new{className = "GraphApp"}

local makeEdge

-- Application to display a crafting hypergraph.
--
-- RO fields:
-- * canvas: Canvas object on which the graph is drawn.
-- * graph: Displayed DirectedHypergraph.
-- * rawPlayer: LuaPlayer object.
-- * renderer: SimpleRenderer object displaying the graph.
-- * sourceVertices: Set of source vertex indices used to compute the layout.
-- * surface: LuaSurface where the graph is drawn.
--
local GraphApp = ErrorOnInvalidRead.new{
    -- Creates a new GraphApp object.
    --
    -- Args:
    -- * object: Table to turn into a GraphApp object (required fields: graph, rawPlayer, sourceVertices, surface).
    --
    -- Returns: The argument turned into a GraphApp object.
    --
    new = function(object)
        local graph = cLogger:assertField(object, "graph")
        local rawPlayer = cLogger:assertField(object, "rawPlayer")
        local sourceVertices = cLogger:assertField(object, "sourceVertices")
        local surface = cLogger:assertField(object, "surface")

        local layout = LayerLayout.new{
            graph = graph,
            sourceVertices = sourceVertices,
        }
        local canvas = Canvas.new{
            players = {rawPlayer},
            surface = surface,
        }
        object.canvas = canvas
        object.renderer = SimpleRenderer.new{
            layout = layout,
            canvas = canvas,
        }
        ErrorOnInvalidRead.setmetatable(object)

        return object
    end,

    -- Creates a default graph & source set from a PrototypeDatabase.
    --
    -- The graph will contain all recipes, and the source set will contain all natural resources.
    --
    -- Args:
    -- * prototypes: The PrototypeDatabase object.
    --
    -- Returns:
    -- * A DirectedHypergraph containing all the recipes.
    -- * A set of vertex indices of the graph, correspongint to all the resources.
    --
    makeDefaultGraphAndSource = function(prototypes)
        local graph = DirectedHypergraph.new()

        for _,recipe in pairs(prototypes.entries.recipe) do
            graph:addEdge(makeEdge(recipe))
        end
        for _,boiler in pairs(prototypes.entries.boiler) do
            graph:addEdge(makeEdge(boiler))
        end

        local sourceVertices = ErrorOnInvalidRead.new()
        for _,resource in pairs(prototypes.entries.resource) do
            for _,product in pairs(resource.products) do
                sourceVertices[product] = true
            end
        end
        for _,offshorePump in pairs(prototypes.entries["offshore-pump"]) do
            for _,product in pairs(offshorePump.products) do
                sourceVertices[product] = true
            end
        end

        return graph,sourceVertices
    end,
}

-- Turns an entry from a PrototypeDatabase into a DirectedHypergraph edge.
--
-- Args:
-- * entry: An entry from PrototypeDatabase (supported types: recipe, boiler)
--
-- Returns: the new edge.
--
makeEdge = function(entry)
    local result = {
        index = entry,
        inbound = {},
        outbound = {},
    }
    for _,ingredient in pairs(entry.ingredients) do
        table.insert(result.inbound, ingredient)
    end
    for _,product in pairs(entry.products) do
        table.insert(result.outbound, product)
    end
    return result
end

return GraphApp