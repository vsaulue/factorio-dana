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
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger
local Metatable
local ValidProductionTypes

-- Mock implementation of Factorio's LuaFluidBoxPrototype.
--
-- See:
-- * https://lua-api.factorio.com/1.0.0/LuaFluidBoxPrototype.html
--
-- Implemented fields & methods:
-- * filter
-- * production_type
-- + CommonMockObject
--
local LuaFluidBoxPrototype = {
    -- Creates a new LuaFluidBoxPrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaFluidBoxPrototype. The new object.
    --
    make = function(rawData)
        local production_type = rawData.production_type or "None"
        if not ValidProductionTypes[production_type] then
            cLogger:error("Invalid production_type: " .. tostring(production_type))
        end

        local filter = rawData.filter
        if filter then
            cLogger:assert(type(filter) == "string", "Invalid filter: string expected.")
        end

        return CommonMockObject.make({
            filter = filter,
            production_type = production_type,
        }, Metatable)
    end,
}

-- Metatable of the LuaFluidBoxPrototype class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaFluidBoxPrototype",

    getters = {
        filter = MockGetters.validTrivial("filter"),
        production_type = MockGetters.validTrivial("production_type"),
    },
}

cLogger = Metatable.cLogger

-- Set<string>. Accepted values for the production_type field.
ValidProductionTypes = {
    input = true,
    ["input-output"] = true,
    None = true,
    output = true,
}

return LuaFluidBoxPrototype
