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
local GraphApp = require("lua/apps/graph/GraphApp")
local GuiElement = require("lua/gui/GuiElement")
local PlayerGui = require("lua/PlayerGui")

local Metatable

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
-- * opened: true if the GUI is opened.
--
local Player = ErrorOnInvalidRead.new{
    -- Creates a new Player object.
    --
    -- Args:
    -- * object: table to turn into the Player object (required fields: graphSurface, prototypes, rawPlayer).
    --
    new = function(object)
        setmetatable(object, Metatable)
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
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        PlayerGui.setmetatable(object.playerGui)
    end,
}

-- Metatable of the Player class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        on_selected_area = function(self, event)
            self.app:on_selected_area(event)
        end,
    },
}

return Player
