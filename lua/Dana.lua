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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local PrototypeDatabase = require("lua/PrototypeDatabase")
local Player = require("lua/Player")

local cLogger = ClassLogger.new{className = "Dana"}

local newSurface

-- Main class of this mod.
--
-- Singleton class.
--
-- Stored in global: yes.
--
-- Fields:
-- * gameScript: LuaGameScript object from the Factorio API.
-- * graphSurface: surface used to draw graphs.
-- * players: map of Player objects, indexed by their Factorio index.
-- * prototypes: PrototypeDatabase wrapping all useful prototypes from Factorio.
--
local Dana = ErrorOnInvalidRead.new{
    -- Creates a new Dana instance.
    --
    -- Args:
    -- * object: Table to turn into a Dana isntance.
    --
    -- Returns: The new Dana object.
    --
    new = function(object)
        local gameScript = cLogger:assertField(object, "gameScript")
        local result = ErrorOnInvalidRead.new{
            graphSurface = newSurface(gameScript),
            players = {},
            prototypes = PrototypeDatabase.new(gameScript),
        }
        for _,rawPlayer in pairs(game.players) do
            result.players[rawPlayer.index] = Player.new({
                graphSurface = result.graphSurface,
                prototypes = result.prototypes,
                rawPlayer = rawPlayer,
            })
        end
        return result
    end,

    -- Restores the metatable of a Dana instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(self)
        ErrorOnInvalidRead.setmetatable(object)
        PrototypeDatabase.setmetatable(object.prototypes)
        for _,player in pairs(object.players) do
            Player.setmetatable(player)
        end
    end,

    -- Function to call in Factorio's on_load event.
    on_load = nil, -- implemented later

    -- Function to call in Factorio's on_init event.
    on_init = nil, -- implemented later

    -- Function to call in Factorio's on_player_selected_area event.
    on_player_selected_area = nil, -- implemented later
}

-- Creates a new surface.
--
-- Args:
-- * gameScript: LuaGameScript object.
--
-- Returns: the new surface.
--
newSurface = function(gameScript)
    local MapGenSettings = {
        height = 1,
        width = 1,
    }
    local namePrefix = script.mod_name
    local result = gameScript.create_surface(namePrefix, MapGenSettings)
    local number = 1
    while not result do
        result = gameScript.create_surface(namePrefix .. "_" .. number, MapGenSettings)
        number = number + 1
    end
    result.set_chunk_generated_status({0, 0}, defines.chunk_generated_status.entities)
    result.always_day = true
    result.freeze_daytime = true
    return result
end

function Dana.on_load()
    Dana.setmetatable(global.Dana)
end

function Dana.on_init()
    global.Dana = Dana.new{
        gameScript = game,
    }
end

function Dana.on_player_selected_area(event)
    local self = global.Dana
    if event.surface.index == self.graphSurface.index then
        local player = self.players[event.player_index]
        player:on_selected_area(event)
    end
end

return Dana
