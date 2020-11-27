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

local AppResources = require("lua/apps/AppResources")
local AppUpcalls = require("lua/apps/AppUpcalls")
local AutoLoaded = require("lua/testing/AutoLoaded")
local Force = require("lua/model/Force")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")

local Metatable

-- Helper class to setup a test environment for an AbstractApp.
--
-- RO Fields:
-- * appResources: AppResources. Resources for the tested app.
-- * factorio: MockFactorio. Test environment.
-- * force: Force. Force of the test player.
-- * player: LuaPlayer. Test player.
-- * prototypes: PrototypeDatabase. Database of this test environment.
-- * upcalls: AppUpcalls. Mock implementation of AppUpcalls (does nothing).
--
local AppTestbench = {
    -- Creates a new AppTestbench object.

    -- Args:
    -- * args: table. May contain the following fields:
    -- **  rawData: table. Construction info from the data phase.
    --
    -- Returns: AppTestbench.
    --
    make = function(args)
        local factorio = MockFactorio.make{
            rawData = args.rawData,
        }
        local prototypes = PrototypeDatabase.new(factorio.game)
        local player = factorio:createPlayer{
            forceName = "player",
        }
        local force = Force.new{
            prototypes = prototypes,
            rawForce = factorio.game.forces.player,
        }
        local upcalls = AutoLoaded.new{
            makeAndSwitchApp = function() end,
            notifyGuiCorrupted = function() end,
            setAppMenu = function() end,
            setPosition = function() end,
        }
        AppUpcalls.check(upcalls)

        local result = {
            appResources = AppResources.new{
                force = force,
                prototypes = prototypes,
                rawPlayer = player,
                surface = factorio.game.create_surface("dana", {}),
                upcalls = upcalls,
            },
            factorio = factorio,
            force = force,
            player = player,
            prototypes = prototypes,
            upcalls = upcalls,
        }
        return setmetatable(result, Metatable)
    end,

    -- Restores the metatable of an AppResources object, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        AppResources.setmetatable(object.appResources)
        Force.setmetatable(object.force)
        PrototypeDatabase.setmetatable(object.prototypes)
    end,
}

-- Metatable of the AppTestbench class.
Metatable = {
    __index = {
        -- Sets all the global variables of a Factorio's environment.
        --
        -- See MockFactorio:setup().
        --
        -- Args:
        -- * self: AppTestbench.
        --
        setup = function(self)
            self.factorio:setup()
        end,
    }
}

return AppTestbench
