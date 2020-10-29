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
local LuaFluidBoxPrototype = require("lua/testing/mocks/LuaFluidBoxPrototype")
local MinableProperties = require("lua/testing/mocks/MinableProperties")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local addFluidbox
local cLogger
local Metatable
local Parsers

-- Mock implementation of Factorio's LuaEntityPrototype.
--
-- See https://lua-api.factorio.com/1.0.0/LuaEntityPrototype.html
--
-- Inherits from AbstractPrototype.
--
-- Implemented fields & methods:
-- * fluid
-- * fluidbox_prototypes (fluid energy source NOT parsed)
-- * mineable_properties
-- * pumping_speed
-- + AbstractPrototype.
--
local LuaEntityPrototype = {
    -- Creates a new LuaEntityPrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaEntityPrototype. The new object.
    --
    make = function(rawData)
        local result = AbstractPrototype.make(rawData, Metatable)
        local mockData = MockObject.getData(result)
        mockData.fluidbox_prototypes = {}

        local parser = Parsers[rawData.type]
        if not parser then
            cLogger:error("Unsupported entity type: " .. tostring(rawData.type))
        elseif type(parser) == "function" then
            parser(mockData, rawData)
        end

        mockData.mineable_properties = MinableProperties.make(rawData.minable)
        return result
    end,

    -- Metatable of the LuaEntityPrototype class.
    Metatable = AbstractPrototype.Metatable:makeSubclass{
        className = "LuaEntityPrototype",

        getters = {
            fluid = MockGetters.validTrivial("fluid"),
            fluidbox_prototypes = MockGetters.validTrivial("fluidbox_prototypes"),
            mineable_properties = MockGetters.validDeepCopy("mineable_properties"),
            pumping_speed = MockGetters.validTrivial("pumping_speed"),
        },
    },
}

-- Adds a fluidbox to a prototype.
--
-- Args:
-- * mockData: LuaEntityPrototype.data. Internal data of the entity prototype.
-- * rawFluidboxData: table. The fluidbox's construction arguments from the data phase.
--
addFluidbox = function(mockData, rawFluidboxData)
    table.insert(mockData.fluidbox_prototypes, LuaFluidBoxPrototype.make(rawFluidboxData))
end

cLogger = LuaEntityPrototype.Metatable.cLogger
Metatable = LuaEntityPrototype.Metatable

-- Map[string]: function or true. Specific parsing function, indexed by prototype type.
Parsers = {
    boiler = function(mockData, rawData)
        addFluidbox(mockData, cLogger:assertFieldType(rawData, "fluid_box", "table"))
        addFluidbox(mockData, cLogger:assertFieldType(rawData, "output_fluid_box", "table"))
    end,

    ["offshore-pump"] = function(mockData, rawData)
        mockData.fluid = cLogger:assertFieldType(rawData, "fluid", "string")
        mockData.pumping_speed = cLogger:assertFieldType(rawData, "pumping_speed", "number")
        addFluidbox(mockData, cLogger:assertFieldType(rawData, "fluid_box", "table"))
    end,

    resource = true,
}

return LuaEntityPrototype
