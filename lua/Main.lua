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
local PrototypeDatabase = require("lua/PrototypeDatabase")
local Player = require("lua/Player")

-- Main class of this mod.
--
-- Singleton class.
--
-- Stored in global: yes.
--
-- Fields:
-- * graph: a DirectedHypergraph with all recipes.
-- * players: map of Player objects, indexed by their Factorio index.
-- * prototypes: PrototypeDatabase wrapping all useful prototypes from Factorio.
--
local Main = {
    -- Function to call in Factorio's on_load event.
    on_load = nil, -- implemented later

    -- Function to call in Factorio's on_init event.
    on_init = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    initGraph = nil, -- implemented later.

    new = nil, -- implemented later.

    -- Restores the metatable of a Main instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        PrototypeDatabase.setmetatable(object.prototypes)
        DirectedHypergraph.setmetatable(object.graph)
        for _,player in pairs(object.players) do
            Player.setmetatable(player)
        end
    end
}

-- Initialize Impl.graph to represent the crafting graph.
--
function Impl.initGraph(self)
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
        self.graph:addEdge(newEdge)
    end
end

function Impl.new(gameScript)
    local result = {
        graph = DirectedHypergraph.new(),
        players = {},
        prototypes = PrototypeDatabase.new(gameScript),
    }
    for _,rawPlayer in pairs(game.players) do
        result.players[rawPlayer.index] = Player.new({rawPlayer = rawPlayer})
    end
    Impl.initGraph(result)
    return result
end

function Main.on_load()
    Impl.setmetatable(global.Main)
end

function Main.on_init()
    global.Main = Impl.new(game)
end

return Main
