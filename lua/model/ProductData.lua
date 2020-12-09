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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ProductAmount = require("lua/model/ProductAmount")

local cLogger = ClassLogger.new{className = "ProductData"}

local Metatable

-- Class holding the data associated to a product in an AbstractTransform.
--
-- RO Fields:
-- * [ProductAmount]: int. Set of ProductAmount in this object, with the number of occurences.
--
local ProductData = ErrorOnInvalidRead.new{
    -- Creates a new ProductData object wrapping a ProductAmount object.
    --
    -- Args:
    -- * productAmount: ProductAmount object to wrap.
    --
    -- Returns: The new ProductData object.
    --
    make = function(productAmount)
        cLogger:assert(productAmount, "missing argument to make().")
        local self = {
            [productAmount] = 1,
        }
        setmetatable(self, Metatable)
        return self
    end,

    -- Restores the metatable of a ProductData object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        for productAmount in pairs(object) do
            ProductAmount.setmetatable(productAmount)
        end
    end,
}

-- Metatable of the ProductData class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a ProductAmount object.
        --
        -- Args:
        -- * self: ProductData object.
        -- * newAmount: ProductAmount object to add.
        --
        addAmount = function(self, newAmount)
            local count = rawget(self, newAmount) or 0
            self[newAmount] = 1 + count
        end,

        -- Gets the average amount of intermediate produced.
        --
        -- Args:
        -- * self: ProductData object.
        --
        -- Returns: The average amount of produced intermediate.
        --
        getAvg = function(self)
            local result = 0
            for productAmount,count in pairs(self) do
                result = result + count * productAmount:getAvg()
            end
            return result
        end,
    },
}

return ProductData
