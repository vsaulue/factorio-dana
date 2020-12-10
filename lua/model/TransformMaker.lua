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
local FlyweightFactory = require("lua/class/FlyweightFactory")
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")

local cLogger = ClassLogger.new{className = "TransformMaker"}

local addProduct
local Metatable

-- Utility class to build AbstractTransform objects.
--
-- RO Fields:
-- * intermediates: IntermediatesDatabase. Intermediates to use as ingredients or products.
-- * transform (optional): table. Future constructor argument for an AbstractTransform.
-- **  ingredients: table.
-- **  products: table.
--
local TransformMaker = ErrorOnInvalidRead.new{
    new = function(object)
        cLogger:assertField(object, "intermediates")
        object.productAmountFactory = FlyweightFactory.new{
            make = ProductAmount.copy,
            valueEquals = ProductAmount.equals,
        }
        object.productDataFactory = FlyweightFactory.new{
            make = ProductData.copy,
            valueEquals = ProductData.equals,
        }
        setmetatable(object, Metatable)
        return object
    end,
}

Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds a product to the transform.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * iType: string. Type of the added Intermediate.
        -- * name: string. Name of the added Intermediate.
        -- * productAmount: Associated ProductAmount object.
        --
        addConstantProduct = function(self, iType, name, count)
            addProduct(self, iType, name, {
                amountMax = count,
                amountMin = count,
                probability = 1,
            })
        end,

        -- Adds an ingredient to the transform.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * iType: string. Type of the added Intermediate.
        -- * name: string. Name of the added Intermediate.
        -- * amount: int. Amount consumed by the transform.
        --
        addIngredient = function(self, iType, name, amount)
            self:addIngredientIntermediate(self.intermediates[iType][name], amount)
        end,

        -- Adds an ingredient to the transform.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * intermediate: Intermediate. Ingredient to add.
        -- * amount: int. Amount consumed by the transform.
        --
        addIngredientIntermediate = function(self, intermediate, amount)
            local ingredients = self.transform.ingredients
            local oldQuantity = (rawget(ingredients, intermediate) or 0)
            ingredients[intermediate] = oldQuantity + amount
        end,

        -- Adds an array of Ingredient from the API.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * rawIngredients: Array<Ingredient>. Ingredients from Factorio's API.
        --
        addRawIngredientArray = function(self, rawIngredients)
            for _,rawIngredient in ipairs(rawIngredients) do
                self:addIngredient(rawIngredient.type, rawIngredient.name, rawIngredient.amount)
            end
        end,

        -- Adds an array of Ingredient from the API.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * rawProduct: Product. Product from Factorio's API.
        --
        addRawProduct = function(self, rawProduct)
            local amountMax = rawProduct.amount
            local amountMin
            if amountMax then
                amountMin = amountMax
            else
                amountMax = rawProduct.amount_max
                amountMin = rawProduct.amount_min
            end
            addProduct(self, rawProduct.type, rawProduct.name, {
                amountMax = amountMax,
                amountMin = amountMin,
                probability = rawProduct.probability or 1,
            })
        end,

        -- Adds an array of Ingredient from the API.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * rawIngredients: Array<Ingredient>. Ingredients from Factorio's API.
        --
        addRawProductArray = function(self, rawProductArray)
            for _,rawProduct in ipairs(rawProductArray) do
                self:addRawProduct(rawProduct)
            end
        end,

        -- Clears the transform field, after running the final value interning pass.
        --
        -- Args:
        -- * self: TransformMaker.
        --
        -- Returns: table. The previous value of the `transform` field.
        --
        finaliseTransform = function(self)
            local transform = self.transform
            local newProducts = {}
            for intermediate,productData in pairs(transform.products) do
                newProducts[intermediate] = self.productDataFactory:get(productData)
            end
            transform.products = newProducts
            self.transform = nil
            return transform
        end,

        -- Resets the transform field, to be used to generate a new transform.
        --
        -- Args:
        -- * self: TransformMaker.
        -- * object (optional): table. Table to use as the new transform.
        --
        newTransform = function(self, object)
            local transform = object or {}
            transform.products = {}
            transform.ingredients = {}
            self.transform = transform
            return transform
        end,
    },
}

-- Adds a product to the transform.
--
-- Args:
-- * self: TransformMaker.
-- * iType: string. Type of the added Intermediate.
-- * name: string. Name of the added Intermediate.
-- * productAmount: Associated ProductAmount object.
--
addProduct = function(self, iType, name, rawAmount)
    if rawAmount.amountMax > 0 and rawAmount.probability > 0 then
        local amount = self.productAmountFactory:get(rawAmount)
        local products = self.transform.products
        local intermediate = self.intermediates[iType][name]
        local productData = rawget(products, intermediate)
        if not productData then
            productData = {
                [amount] = 1,
            }
            products[intermediate] = productData
        else
            local count = rawget(productData, amount) or 0
            productData[amount] = 1 + count
        end
    end
end

return TransformMaker
