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

local ClassLogger = require("lua/logger/ClassLogger")
local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local MockGetters = require("lua/testing/mocks/MockGetters")

local cLogger = ClassLogger.new{className = "AbstractPrototype"}

local checkType
local LocalisedNamePrefix
local Metatable

-- Base class for all mocks of prototypes.
--
-- Implements CommonMockObject.
--
-- Implemented fields & methods:
-- * localised_name
-- * name
-- * type
--
local AbstractPrototype = {
    -- Creates a new AbstractPrototype object.
    --
    -- Args:
    -- * rawData: table. Construction info from the data phase.
    -- * metatable (optional): table. Metatable to set.
    --
    -- Returns: AbstractPrototype. The new object.
    --
    make = function(rawData, metatable)
        local pType = cLogger:assertField(rawData, "type")
        local name = cLogger:assertFieldType(rawData, "name", "string")

        local result = CommonMockObject.make({
            localised_name = { LocalisedNamePrefix[pType] .. "." .. name },
            name = name,
            type = checkType(pType),
        }, metatable or Metatable)
        return result
    end,

    -- Metatable of the AbstractPrototype class.
    Metatable = CommonMockObject.Metatable:makeSubclass{
        className = "AbstractPrototype",
        getters = {
            localised_name = MockGetters.validTrivial("localised_name"),
            name = MockGetters.validTrivial("name"),
            type = MockGetters.validTrivial("type"),
        },
    }
}

-- Checks the value of the "type" field.
--
-- Args:
-- * value: any. Value of the "type" field to test.
--
-- Returns: string. The argument.
--
checkType = function(value)
    cLogger:assert(type(value) == "string", "Invalid prototype")
    cLogger:assert(LocalisedNamePrefix[value], "Invalid prototype type: " .. tostring(value))
    return value
end

-- Map[string] -> string. Prefix used for localised_name, indexed by the prototype type.
LocalisedNamePrefix = {
    fluid = "fluid-name",
    item = "item-name",
    ["offshore-pump"] = "entity-name",
    recipe = "recipe-name",
    resource = "entity-name",
}

Metatable = AbstractPrototype.Metatable

return AbstractPrototype
