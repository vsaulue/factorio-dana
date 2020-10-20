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

local AbstractPrototype = require("lua/testing/mocks/AbstractPrototype")
local Ingredient = require("lua/testing/mocks/Ingredient")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")
local Product = require("lua/testing/mocks/Product")

local cLogger
local Metatable
local parseRecipeData

-- Mock implementation of Factorio's LuaRecipePrototype.
--
-- See https://lua-api.factorio.com/1.0.0/LuaRecipePrototype.html
--
-- Inherits from AbstractPrototype.
--
-- Implemented fields & methods:
-- * ingredients
-- * products
-- + AbstractPrototype.
--
local LuaRecipePrototype = {
    -- Creates a new LuaRecipePrototype object.
    --
    -- Args:
    -- * rawData: table. Construction argument from the data phase.
    --
    -- Returns: LuaRecipePrototype. The new object.
    --
    make = function(rawData)
        if rawData.type ~= "recipe" then
            cLogger:error("Invalid type: " .. tostring(rawData.type))
        end
        local result = AbstractPrototype.make(rawData, Metatable)

        local mockData = MockObject.getData(result)
        local recipeData = rawData.normal or rawData.expensive or rawData
        parseRecipeData(mockData, recipeData)

        return result
    end,

    -- Metatable of the LuaRecipePrototype class.
    Metatable = AbstractPrototype.Metatable:makeSubclass{
        className = "LuaRecipePrototype",

        getters = {
            ingredients = MockGetters.validDeepCopy("ingredients"),
            products = MockGetters.validDeepCopy("products"),
        },
    },
}

cLogger = LuaRecipePrototype.Metatable.cLogger
Metatable = LuaRecipePrototype.Metatable

-- Parses the RecipeData section of a recipe.
--
-- See https://wiki.factorio.com/Prototype/Recipe#Recipe_data
--
-- Args:
-- * mockData: table. Internal data table of the MockObject being built.
-- * recipeData: table. Table holding the RecipeData values from the raw data.
--
parseRecipeData = function(mockData, recipeData)
    local ingredients = {}
    for index,ingredientData in ipairs(recipeData.ingredients) do
        ingredients[index] = Ingredient.make(ingredientData)
    end
    mockData.ingredients = ingredients

    local products = {}
    local result = recipeData.result
    local results = recipeData.results
    if result then
        cLogger:assert(not results, "Duplicate 'result' & 'results' fields are forbidden.")
        local result_count = recipeData.result_count or 1
        products[1] = Product.make{result, result_count}
    else
        for index,productData in ipairs(results) do
            products[index] = Product.make(productData)
        end
    end
    mockData.products = products
end

return LuaRecipePrototype
