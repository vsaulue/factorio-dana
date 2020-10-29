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

local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local LuaFluidBoxPrototype = require("lua/testing/mocks/LuaFluidBoxPrototype")
local MockGetters = require("lua/testing/mocks/MockGetters")

local cLogger
local Metatable

-- Mock implementation of Factorio's LuaFluidEnergySourcePrototype.
--
-- See:
-- * https://lua-api.factorio.com/1.0.0/LuaFluidEnergySourcePrototype.html
-- * https://wiki.factorio.com/Types/EnergySource#Fluid_energy_source
--
-- Implemented fields & methods:
-- * fluid_box
-- + CommonMockObject
--
local LuaFluidEnergySourcePrototype = {
    -- Creates a new LuaFluidEnergySourcePrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaFluidEnergySourcePrototype. The new object.
    --
    make = function(rawData)
        cLogger:assert(rawData.type == "fluid", "Invalid type ('fluid' expected).")
        return CommonMockObject.make({
            fluid_box = LuaFluidBoxPrototype.make(cLogger:assertField(rawData, "fluid_box")),
        }, Metatable)
    end,
}

-- Metatable of the LuaFluidEnergySourcePrototype class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaFluidEnergySourcePrototype",

    getters = {
        fluid_box = MockGetters.validTrivial("fluid_box"),
    },
}

cLogger = Metatable.cLogger

return LuaFluidEnergySourcePrototype
