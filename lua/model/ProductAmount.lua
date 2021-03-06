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

local cLogger = ClassLogger.new{className = "ProductAmount"}

local Metatable
local new

-- Record describing the amount of an intermediate produced in an AbstractTransform.
--
-- This is essentially an alias to Factorio's Product type.
--
-- Fields:
-- * amountMax: Maximum amount produced by this recipe (see Product.amount_max).
-- * amountMin: Maximum amount produced by this recipe (see Product.amount_min).
-- * probability: Probability for this intermediate to be produced (see Product.probability).
--
local ProductAmount = ErrorOnInvalidRead.new{
    -- Creates a ProductAmount object for a fixed amount of product.
    --
    -- Args:
    -- * amount: The amount of intermediate always generated by the transform.
    --
    -- Returns: The new ProductAmount object.
    --
    makeConstant = function(amount)
        return new{
            amountMax = amount,
            amountMin = amount,
            probability = 1,
        }
    end,

    -- Creates a ProductAmount from a Product object of Factorio's API.
    --
    -- Args:
    -- * rawProduct: Product object from Factorio.
    --
    -- Returns: The new ProductAmount object.
    --
    makeFromRawProduct = function(rawProduct)
        local amountMax = rawProduct.amount
        local amountMin
        if amountMax then
            amountMin = amountMax
        else
            amountMax = rawProduct.amount_max
            amountMin = rawProduct.amount_min
        end
        return new{
            amountMax = amountMax,
            amountMin = amountMin,
            probability = rawProduct.probability or 1,
        }
    end,

    -- Creates a new ProductAmount object.
    --
    -- Args:
    -- * object: Table to turn into a ProductAmount object.
    --
    -- Returns: The argument turned into a ProductAmount object.
    --
    new = function(object)
        cLogger:assertField(object, "amountMax")
        cLogger:assertField(object, "amountMin")
        cLogger:assertField(object, "probability")
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a ProductAmount object, and all its owned objects.
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the ProductAmount class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets the average amount of intermediate produced.
        --
        -- Args:
        -- * self: ProductAmount object.
        --
        -- Returns: The average amount of produced intermediate.
        --
        getAvg = function(self)
            return self.probability * (self.amountMax + self.amountMin) / 2
        end,
    }
}

new = ProductAmount.new

return ProductAmount
