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

local cLogger = ClassLogger.new{className = "Ingredient"}

local ValidTypes

-- Mock implementation of Factorio's Ingredient.
--
-- See https://lua-api.factorio.com/1.0.0/Concepts.html#Ingredient
--
-- Implemented fields & methods:
-- * amount
-- * name
-- * type
--
local Ingredient = {
    -- Creates a new Ingredient object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: Ingredient. The new object.
    --
    make = function(rawData)
        local type = rawData.type
        local name
        local amount
        if type then
            amount = cLogger:assertFieldType(rawData, "amount", "number")
            name = cLogger:assertFieldType(rawData, "name", "string")
            if not ValidTypes[type] then
                cLogger:error("Unknown type: " .. tostring(type))
            end
        else
            amount = cLogger:assertFieldType(rawData, 2, "number")
            name = cLogger:assertFieldType(rawData, 1, "string")
            type = "item"
        end
        return {
            amount = amount,
            name = name,
            type = type,
        }
    end,
}

-- Set[string]. Accepted values for the "type" field.
ValidTypes = {
    fluid = true,
    item = true,
}

return Ingredient
