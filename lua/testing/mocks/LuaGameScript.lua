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
local LuaFluidPrototype = require("lua/testing/mocks/LuaFluidPrototype")
local LuaItemPrototype = require("lua/testing/mocks/LuaItemPrototype")
local MockGetters = require("lua/testing/mocks/MockGetters")

local cLogger
local Metatable
local parse

-- Mock implementation of Factorio's LuaGameScript.
--
-- See https://lua-api.factorio.com/1.0.0/LuaGameScript.html
--
-- Inherits from CommonMockObject.
--
-- Implemented fields & methods:
-- * fluid_prototypes
-- * item_prototypes
-- + AbstractPrototype.
--
local LuaGameScript = {
    -- Creates a new LuaGameScript object.
    --
    -- Args:
    -- * rawData: table. Construction info from the data phase.
    --
    -- Returns: LuaGameScript. The new object.
    make = function(rawData)
        local selfData = {
            fluid_prototypes = {},
            item_prototypes = {},
        }
        parse(selfData.fluid_prototypes, rawData.fluid, LuaFluidPrototype.make)
        parse(selfData.item_prototypes, rawData.item, LuaItemPrototype.make)
        return CommonMockObject.make(selfData, Metatable)
    end,
}

-- Metatable of the LuaGameScript class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaGameScript",

    getters = {
        fluid_prototypes = MockGetters.validReadOnly("fluid_prototypes"),
        item_prototypes = MockGetters.validReadOnly("item_prototypes"),
    },
}

cLogger = Metatable.cLogger

-- Generates prototypes from a specific map.
--
-- Args:
-- * outputTable[string]: AbstractPrototype. Map where the generated prototypes will be stored
--       (indexed by prototype name).
-- * inputTable[string]: table. Construction info of each prototype from the data phase
--       (indexed by prototype name).
-- * prototypeMaker: function(table) -> AbstractPrototype. Function to generate the prototypes.
--
parse = function(outputTable, inputTable, prototypeMaker)
    if inputTable then
        for name,rawPrototypeData in pairs(inputTable) do
            local newPrototype = prototypeMaker(rawPrototypeData)
            cLogger:assert(name == newPrototype.name, "Prototype at index '" .. tostring(name) .. "' has a mismatching name")
            cLogger:assert(not outputTable[name], "Duplicate prototype name: " .. tostring(name))
            outputTable[name] = newPrototype
        end
    end
end

return LuaGameScript
