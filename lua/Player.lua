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

local GraphApp = require("lua/apps/GraphApp")
local Gui = require("lua/gui/Gui")
local GuiElement = require("lua/gui/GuiElement")
local PlayerGui = require("lua/PlayerGui")

-- Class holding data associated to a player in this mod.
--
-- Stored in global: yes
--
-- Fields:
-- * app: Current application.
-- * rawPlayer: Associated LuaPlayer instance.
-- * graphSurface: LuaSurface used to display graphs to this player.
-- * prototypes: PrototypeDatabase object.
--
-- RO properties:
-- * gui: rawPlayer.gui wrapped in a Gui object.
-- * opened: true if the GUI is opened.
--
local Player = {
    new = nil, -- implemented later

    setmetatable = nil, -- implemented later
}

local on_selected_area = function(self, event)
    self.app:on_selected_area(event)
end

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the Player class.
    Metatable = {
        __index = function(self, fieldName)
            local result = nil
            if fieldName == "gui" then
                result = Gui.new({rawGui = self.rawPlayer.gui})
            elseif fieldName == "on_selected_area" then
                result = on_selected_area
            end
            return result
        end,
    },
}

-- Creates a new Player object.
--
-- Args:
-- * object: table to turn into the Player object (required fields: graphSurface, prototypes, rawPlayer).
--
function Player.new(object)
    setmetatable(object, Impl.Metatable)
    object.opened = false
    object.playerGui = PlayerGui.new{
        player = object,
    }
    -- default app for now
    local graph,sourceVertices = GraphApp.makeDefaultGraphAndSource(object.prototypes)
    object.app = GraphApp.new{
        graph = graph,
        rawPlayer = object.rawPlayer,
        sourceVertices = sourceVertices,
        surface = object.graphSurface,
    }
    --
    return object
end

-- Restores the metatable of a Player instance, and all its owned objects.
--
-- Args:
-- * object: Table to modify.
--
function Player.setmetatable(object)
    setmetatable(object, Impl.Metatable)
end

return Player
