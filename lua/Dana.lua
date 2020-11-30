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
local Force = require("lua/model/Force")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local PlayerController = require("lua/controller/PlayerController")

local getModVersion
local Metatable
local newSurface

-- Main class of this mod.
--
-- Singleton class.
--
-- Stored in global: yes.
--
-- Fields:
-- * forces[forceIndex]: Map of Force objects, indexed by the index of the wrapped LuaForce.
-- * graphSurface: surface used to draw graphs.
-- * players: map of PlayerController objects, indexed by their Factorio index.
-- * prototypes: PrototypeDatabase wrapping all useful prototypes from Factorio.
-- * version: String representing the version of the mod's persisted data (format: "a.b.c").
--
-- Methods: See Metatable.__index.
--
local Dana = ErrorOnInvalidRead.new{
    -- Creates a new Dana instance.
    --
    -- Args:
    -- * object: Table to turn into a Dana isntance.
    --
    -- Returns: The new Dana object.
    --
    new = function()
        local result = {
            forces = ErrorOnInvalidRead.new(),
            graphSurface = newSurface(game),
            players = {},
            prototypes = PrototypeDatabase.new(game),
            version = getModVersion(game),
        }

        for _,rawForce in pairs(game.forces) do
            result.forces[rawForce.index] = Force.new{
                prototypes = result.prototypes,
                rawForce = rawForce,
            }
        end

        for _,rawPlayer in pairs(game.players) do
            result.players[rawPlayer.index] = PlayerController.new({
                force = result.forces[rawPlayer.force.index],
                graphSurface = result.graphSurface,
                rawPlayer = rawPlayer,
            })
        end

        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a Dana instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        PrototypeDatabase.setmetatable(object.prototypes)

        ErrorOnInvalidRead.setmetatable(object.forces)
        for _,force in pairs(object.forces) do
            Force.setmetatable(force)
        end

        for _,player in pairs(object.players) do
            PlayerController.setmetatable(player)
        end
    end,
}

-- Metatable of the dana class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Callback for Factorio's event of the same name.
        --
        -- Args:
        -- * self: Dana object.
        -- * configChangedData: ConfigurationChangedData object from Factorio.
        --
        on_configuration_changed = function(self, configChangedData)
            self.prototypes:rebuild(game)
            for _,force in pairs(self.forces) do
                force:rebuild()
            end
            for _,player in pairs(self.players) do
                player:reset()
            end
        end,

        -- Callback for Factorio's event of the same name.
        --
        -- Args:
        -- * self: Dana object.
        -- * event: Factorio event.
        --
        on_force_created = function(self, event)
            local rawForce = event.force
            self.forces[rawForce.index] = Force.new{
                prototypes = self.prototypes,
                rawForce = rawForce,
            }
        end,

        -- Callback for Factorio's event of the same name.
        --
        -- Args:
        -- * self: Dana.
        -- * event: table. Factorio event.
        --
        on_lua_shortcut = function(self, event)
            local player = self.players[event.player_index]
            player:onLuaShortcut(event)
        end,

        -- Callback for Factorio's event of the same name.
        --
        -- Args:
        -- * self: Dana object.
        -- * event: Factorio event.
        --
        on_player_changed_surface = function(self, event)
            local player = self.players[event.player_index]
            player:onChangedSurface(event)
        end,

        -- Callback for Factorio's event of the same name.
        --
        -- Args:
        -- * self: Dana object.
        -- * event: Factorio event.
        --
        on_player_created = function(self, event)
            local playerIndex = event.player_index
            local rawPlayer = game.players[playerIndex]
            self.players[playerIndex] = PlayerController.new{
                force = self.forces[rawPlayer.force.index],
                graphSurface = self.graphSurface,
                rawPlayer = rawPlayer,
            }
        end,

        -- Callback for Factorio's event of the same name.
        --
        -- Args:
        -- * self: Dana object.
        -- * event: Factorio event.
        --
        on_player_selected_area = function(self, event)
            if event.surface.index == self.graphSurface.index then
                local player = self.players[event.player_index]
                player:onSelectedArea(event)
            end
        end,
    },
}

-- Gets the currently running version of this mod.
--
-- Args:
-- * gameScript: LuaGameScript object.
--
-- Returns: A string representing the running version (format: "a.b.c").
--
getModVersion = function(gameScript)
    return gameScript.active_mods[script.mod_name]
end

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

    local newSurfaceName = namePrefix
    local number = 1
    while gameScript.surfaces[newSurfaceName] do
        newSurfaceName = namePrefix .. "_" .. number
        number = number + 1
    end
    local result = gameScript.create_surface(newSurfaceName, MapGenSettings)
    result.set_chunk_generated_status({0, 0}, defines.chunk_generated_status.entities)
    result.always_day = true
    result.freeze_daytime = true
    return result
end

return Dana
