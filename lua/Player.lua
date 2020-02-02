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

local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local Gui = require("lua/gui/Gui")
local GuiElement = require("lua/gui/GuiElement")
local LayerLayout = require("lua/layouts/layer/LayerLayout")
local SimpleRenderer = require("lua/SimpleRenderer")

-- Class holding data associated to a player in this mod.
--
-- Stored in global: yes
--
-- Fields:
-- * rawPlayer: Associated LuaPlayer instance.
-- * graph: DirectedHypergraph currently displayed to this player.
-- * graphSurface: LuaSurface used to display graphs to this player.
--
-- RO properties:
-- * gui: rawPlayer.gui wrapped in a Gui object.
-- * opened: true if the GUI is opened.
--
local Player = {
    new = nil, -- implemented later

    setmetatable = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the Player class.
    Metatable = {
        __index = function(self, fieldName)
            local result = nil
            if fieldName == "gui" then
                result = Gui.new({rawGui = self.rawPlayer.gui})
            end
            return result
        end,
    },

    buildGraph = nil,

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
    end,

    initGui = nil, -- implemented later

    renderGraph = nil, -- implemented later

    -- Callbacks for the top-left button.
    StartCallbacks = {
        index = "startButton",
        on_click = function(self, event)
            local player = self.player
            local targetPosition = self.previousPosition
            self.previousPosition = player.rawPlayer.position
            if player.opened then
                player.rawPlayer.teleport(targetPosition, self.previousSurface)
            else
                self.previousSurface = player.rawPlayer.surface
                player.rawPlayer.teleport(targetPosition, player.graphSurface)
            end
            player.opened = not player.opened
        end,
    },
}

GuiElement.newCallbacks(Impl.StartCallbacks)

-- Creates a new Player object.
--
-- Args:
-- * object: table to turn into the Player object (must have a "rawPlayer" field).
--
function Player.new(object)
    setmetatable(object, Impl.Metatable)
    object.graph = DirectedHypergraph.new()
    object.opened = false
    Impl.buildGraph(object)
    Impl.initGui(object)
    Impl.renderGraph(object)
    return object
end

-- Restores the metatable of a Player instance, and all its owned objects.
--
-- Args:
-- * object: Table to modify.
--
function Player.setmetatable(object)
    setmetatable(object, Impl.Metatable)
    DirectedHypergraph.setmetatable(object.graph)
end

-- Initialize the "graph" field of a Player object.
--
-- Args:
-- * self: Player whose graph will be built.
--
function Impl.buildGraph(self)
    for _,recipe in pairs(self.prototypes.entries.recipe) do
        self.graph:addEdge(Impl.makeEdge(recipe))
    end
    for _,boiler in pairs(self.prototypes.entries.boiler) do
        self.graph:addEdge(Impl.makeEdge(boiler))
    end
end

-- Initialize the GUI of a player.
--
-- Args:
-- * self: Player whose GUI will be created.
--
function Impl.initGui(self)
    self.gui.left:add({
        type = "button",
        name = "menuButton",
        caption = "Chains",
    },{
        callbacksIndex = Impl.StartCallbacks.index,
        player = self,
        previousPosition = {0,0},
    })
end

-- Renders the current graph of this player.
--
-- Args:
-- * self: Player object.
--
function Impl.renderGraph(self)
    local rawMaterials = {}
    for _,resource in pairs(self.prototypes.entries.resource) do
        for _,product in pairs(resource.products) do
            rawMaterials[product] = true
        end
    end
    for _,offshorePump in pairs(self.prototypes.entries["offshore-pump"]) do
        for _,product in pairs(offshorePump.products) do
            rawMaterials[product] = true
        end
    end

    local layout = LayerLayout.new(self.graph,rawMaterials)
    local renderer = SimpleRenderer.new({
        rawPlayer = self.rawPlayer,
        surface = self.graphSurface,
    })
    renderer:draw(layout)
end

return Player
