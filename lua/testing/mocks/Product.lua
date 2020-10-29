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

local cLogger = ClassLogger.new{className = "Product"}

local ValidTypes

-- Mock implementation of Factorio's Product.
--
-- See https://lua-api.factorio.com/1.0.0/Concepts.html#Product
--
-- Implemented fields & methods:
-- * amount
-- * amount_max
-- * amount_min
-- * name
-- * probability
-- * type
--
local Product = {
    -- Creates a new Product object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: Product. The new object.
    --
    make = function(rawData)
        local type = rawData.type or "item"
        cLogger:assert(ValidTypes[type], "Unknown type: " .. tostring(type))
        local name = rawData.name
        local amount
        local amount_max
        local amount_min
        local probability
        if name then
            amount = rawData.amount
            if not amount then
                amount_max = cLogger:assertFieldType(rawData, "amount_max", "number")
                amount_min = cLogger:assertFieldType(rawData, "amount_min", "number")
                cLogger:assert(amount_max >= amount_min, "amount_max must be superior to amount_min.")
            end

            if rawData.probability then
                probability = cLogger:assertFieldType(rawData, "probability", "number")
                assert(0 <= probability and probability <= 1, "Invalid probability (outsude [0;1]).")
            end
        else
            amount = cLogger:assertFieldType(rawData, 2 , "number")
            name = cLogger:assertFieldType(rawData, 1, "string")
            type = "item"
        end
        return {
            type = type,
            name = name;
            amount = amount,
            amount_max = amount_max,
            amount_min = amount_min,
            probability = probability,
        }
    end,
}

-- Set[string]. Accepted values for the "type" field.
ValidTypes = {
    fluid = true,
    item = true,
}

return Product
