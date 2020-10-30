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
local MockObject = require("lua/testing/mocks/MockObject")

local checkType
local cLogger
local Metatable

-- Mock implementation of Factorio's LuaItemPrototype.
--
-- See https://lua-api.factorio.com/1.0.0/LuaItemPrototype.html
--
-- Inherits from AbstractPrototype.
--
-- Implemented fields & methods:
-- * burnt_result
-- + AbstractPrototype.
--
local LuaItemPrototype = {
    -- Creates a new LuaItemPrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaItemPrototype. The new object.
    --
    make = function(rawData)
        -- Note: too restrictive (there are valid subtypes).
        cLogger:assert(AbstractPrototype.ItemTypes[rawData.type], "Unsupported type: " .. rawData.type)
        local result = AbstractPrototype.make(rawData, Metatable)
        local mockData = MockObject.getData(result)
        local burnt_result = rawData.burnt_result
        if burnt_result then
            cLogger:assert(type(burnt_result) == "string", "burnt_result must be a string.")
            mockData.burnt_result = burnt_result
        end
        return result
    end,

    -- Metatable of the LuaItemPrototype class.
    Metatable = AbstractPrototype.Metatable:makeSubclass{
        className = "LuaItemPrototype",

        getters = {
            burnt_result = MockGetters.validTrivial("burnt_result"),
        },
    }
}

cLogger = LuaItemPrototype.Metatable.cLogger
Metatable = LuaItemPrototype.Metatable

return LuaItemPrototype
