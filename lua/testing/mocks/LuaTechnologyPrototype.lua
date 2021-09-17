-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local cLogger
local Metatable
local parsePrerequisites

-- Mock implementation of Factorio's LuaTechnologyPrototype.
--
-- See https://lua-api.factorio.com/1.1.39/LuaTechnologyPrototype.html
--
-- Inherits from AbstractPrototype.
--
-- Implemented fields & methods:
-- * prerequisites
-- + AbstractPrototype.
--
local LuaTechnologyPrototype = {
    -- Creates a new LuaTechnologyPrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaTechnologyPrototype. The new object.
    --
    make = function(rawData)
        if rawData.type ~= "technology" then
            cLogger:error("Invalid type: " .. tostring(rawData.type))
        end

        local result = AbstractPrototype.make(rawData, Metatable)
        local mockData = MockObject.getData(result)
        parsePrerequisites(mockData, rawData)

        return result
    end,
}

-- Metatable of the LuaTechnologyPrototype class.
Metatable = AbstractPrototype.Metatable:makeSubclass{
    className = "LuaTechnologyPrototype",
    getters = {
        prerequisites = MockGetters.validShallowCopy("prerequisites"),
        type = MockGetters.hide("type"),
    }
}

cLogger = Metatable.cLogger

-- Parses the prerequisites field of a technology.
--
-- Args:
-- * mockData: table. Internal data table of the MockObject being built.
-- * technologyData: table. Table holding the RecipeData values from the raw data.
--
parsePrerequisites = function(mockData, technologyData)
    local prerequisites = {}
    local rawPrerequisites = technologyData.prerequisites
    if rawPrerequisites then
        if type(rawPrerequisites) ~= "table" then
            cLogger:error("Invalid prerequisites: table expected, got '" .. type(rawPrerequisites) .. "'.")
        end
        for _,prerequisiteName in ipairs(rawPrerequisites) do
            if type(prerequisiteName) ~= "string" then
                cLogger:error("Invalid prerequisite: 'string' expected, got '" .. type(prerequisiteName) .. "'.")
            end
            prerequisites[prerequisiteName] = true
        end
    end
    mockData.prerequisites = prerequisites
end

return LuaTechnologyPrototype
