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
local Product = require("lua/testing/mocks/Product")

local cLogger = ClassLogger.new{className = "MinableProperties"}

-- Mock for Factorio's MinableProperties.
--
-- See:
-- * https://lua-api.factorio.com/1.0.0/LuaEntityPrototype.html#LuaEntityPrototype.mineable_properties
-- * https://wiki.factorio.com/Types/MinableProperties
--
-- Implemented fields & methods:
-- * fluid_amount
-- * minable
-- * products
-- * required_fluid
--
local MinableProperties = {
    -- Creates a new MinableProperties object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: MinableProperties. The new object.
    --
    make = function(rawData)
        local minable = (rawData ~= nil)
        local products = nil
        local fluid_amount = nil
        local required_fluid = nil
        if minable then
            local results = rawData.results
            local result = rawData.result
            if results then
                products = {}
                for index,rawProduct in ipairs(results) do
                    products[index] = Product.make(rawProduct)
                end
            elseif result then
                products = {
                    Product.make{ rawData.result, rawData.count or 1}
                }
            end
            required_fluid = rawData.required_fluid
            if required_fluid then
                cLogger:assert(type(required_fluid) == "string", "Invalid type for required_fluid (string expected).")
                fluid_amount = rawData.fluid_amount or 0
                cLogger:assert(type(fluid_amount) == "number", "Invalid type for fluid_amount (number required).")
            end
        end
        return {
            fluid_amount = fluid_amount,
            minable = minable,
            products = products,
            required_fluid = required_fluid,
        }
    end,
}

return MinableProperties
