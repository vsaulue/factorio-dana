-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local DirectedHypergraph = require("lua/DirectedHypergraph")
local Player = require("lua/Player")

local Main = {
    -- Function to call in Factorio's on_load event.
    on_load = nil, -- implemented later

    -- Function to call in Factorio's on_init event.
    on_init = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Map of Player instances, indexed by their rawPlayer.index (stored in global).
    players = {},

    -- Graph hodling crafting chains (vertices: items, edges: recipes).
    graph = DirectedHypergraph.new(),

    initGraph = nil, -- implemented later.
}

function Main.on_load()
    Impl.graph = global.graph
    DirectedHypergraph.setmetatable(Impl.graph)

    Impl.players = global.players
    for _,player in pairs(Impl.players) do
        Player.setmetatable(player)
    end
end

function Main.on_init()
    global.graph = Impl.graph
    Impl.initGraph()

    global.players = Impl.players
    for _,rawPlayer in pairs(game.players) do
        Impl.players[rawPlayer.index] = Player.new({rawPlayer = rawPlayer})
    end
end

-- Initialize Impl.graph to represent the crafting graph.
--
function Impl.initGraph()
    for _,recipe in pairs(game.recipe_prototypes) do
        local newEdge = {
            index = recipe.name,
            inbound = {},
            outbound = {},
        }
        for _,ingredient in pairs(recipe.ingredients) do
            table.insert(newEdge.inbound, ingredient.name)
        end
        for _,product in pairs(recipe.products) do
            table.insert(newEdge.outbound, product.name)
        end
        Impl.graph:addEdge(newEdge)
    end
end

return Main
