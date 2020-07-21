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

local makeIntermediateSet
local Metatable

-- Transform associated to a recipe.
--
-- Recipes are the majority of transforms: furnaces, refineries or assembling machines use recipes.
--
-- RO fields: same as AbstractTransform.
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
            ingredients = makeIntermediateSet(recipePrototype.ingredients, intermediatesDatabase),
            products = makeIntermediateSet(recipePrototype.products, intermediatesDatabase),
            rawPrototype = recipePrototype,
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
}

-- Metatable of the RecipeTransform class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform:generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("recipe", self.rawPrototype)
        end,
    },
}

-- Creates a set of Intermediate from an array of ingredients/products from Factorio.
--
-- Args:
-- * ingredientsOrProducts: Array of Ingredient or Products.
-- * intermediatesDatabase: Database containing the Intermediates to return.
--
-- Returns: A set containing the Intermediate objects wrapping the values of the array.
--
makeIntermediateSet = function(ingredientsOrProducts, intermediatesDatabase)
    local result = ErrorOnInvalidRead.new()
    for _,rawIntermediate in pairs(ingredientsOrProducts) do
        local intermediate = intermediatesDatabase:getIngredientOrProduct(rawIntermediate)
        result[intermediate] = true
    end
    return result
end

return RecipeTransform
