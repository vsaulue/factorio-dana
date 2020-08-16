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

local AbstractTransform = require("lua/model/AbstractTransform")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local makeIngredientSet
local makeProductSet
local Metatable

-- Transform associated to a recipe.
--
-- Recipes are the majority of transforms: furnaces, refineries or assembling machines use recipes.
--
-- Inherits from AbstractTransform.
--
-- RO Fields:
-- * rawRecipe: RecipePrototype wrapped by this transform.
--
local RecipeTransform = ErrorOnInvalidRead.new{
    -- Creates a new RecipeTransform from a recipe prototype.
    --
    -- Args:
    -- * recipePrototype: Factorio prototype of a recipe.
    -- * intermediatesDatabase: Database containing the Intermediate object to use for this transform.
    --
    -- Returns: The new RecipeTransform object.
    --
    make = function(recipePrototype, intermediatesDatabase)
        return AbstractTransform.new({
            ingredients = makeIngredientSet(recipePrototype.ingredients, intermediatesDatabase),
            products = makeProductSet(recipePrototype.products, intermediatesDatabase),
            rawRecipe = recipePrototype,
            type = "recipe",
        }, Metatable)
    end,

    -- Restores the metatable of a RecipeTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractTransform.setmetatable(object, Metatable)
    end,

    -- LocalisedString representing the type.
    TypeLocalisedStr = AbstractTransform.makeTypeLocalisedStr("recipeType"),
}

-- Metatable of the RecipeTransform class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform:generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("recipe", self.rawRecipe)
        end,

        -- Implements AbstractTransform:getTypeStr().
        getShortName = function(self)
            return self.rawRecipe.localised_name
        end,

        -- Implements AbstractTransform:getTypeStr().
        getTypeStr = function(self)
            return RecipeTransform.TypeLocalisedStr
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractTransform.Metatable.__index})

-- Creates a set of Intermediate from an array of ingredients from Factorio.
--
-- Args:
-- * ingredients: Array of Ingredient.
-- * intermediatesDatabase: Database containing the Intermediates to return.
--
-- Returns: A set containing the Intermediate objects wrapping the values of the array.
--
makeIngredientSet = function(ingredients, intermediatesDatabase)
    local result = ErrorOnInvalidRead.new()
    for _,ingredient in pairs(ingredients) do
        local intermediate = intermediatesDatabase:getIngredientOrProduct(ingredient)
        result[intermediate] = true
    end
    return result
end

-- Creates a set of Intermediate from an array of products from Factorio.
--
-- Args:
-- * products: Array of Product.
-- * intermediatesDatabase: Database containing the Intermediates to return.
--
-- Returns: A set containing the Intermediate objects wrapping the values of the array.
--
makeProductSet = function(products, intermediatesDatabase)
    local result = ErrorOnInvalidRead.new()
    for _,product in pairs(products) do
        local maxAmount = product.amount or product.amount_max
        if (maxAmount > 0) and (product.probability > 0) then
            local intermediate = intermediatesDatabase:getIngredientOrProduct(product)
            result[intermediate] = true
        end
    end
    return result
end

return RecipeTransform
