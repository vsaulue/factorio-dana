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

local AbstractPrototype = require("lua/testing/mocks/AbstractPrototype")
local MockGetters = require("lua/testing/mocks/MockGetters")

local cLogger
local Metatable

-- Mock implementation of Factorio's LuaFluidPrototype.
--
-- See https://lua-api.factorio.com/1.0.0/LuaFluidPrototype.html
--
-- Inherits from AbstractPrototype.
--
-- Implemented fields & methods:
-- + AbstractPrototype.
--
local LuaFluidPrototype = {
    -- Creates a new LuaFluidPrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaFluidPrototype. The new object.
    --
    make = function(rawData)
        if rawData.type ~= "fluid" then
            cLogger:error("Invalid type: " .. tostring(rawData.type))
        end
        return AbstractPrototype.make(rawData, Metatable)
    end,
}

-- Metatable of the LuaFluidPrototype class.
Metatable = AbstractPrototype.Metatable:makeSubclass{
    className = "LuaFluidPrototype",
    getters = {
        type = MockGetters.hide("type"),
    }
}

cLogger = Metatable.cLogger

return LuaFluidPrototype
