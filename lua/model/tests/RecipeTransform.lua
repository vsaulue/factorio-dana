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

local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local RecipeTransform = require("lua/model/RecipeTransform")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("RecipeTransform", function()
    local gameScript
    local intermediates
    local prototype
    setup(function()
        gameScript = LuaGameScript.make{
            item = {
                coal = {type = "item", name = "coal"},
            },
            fluid = {
                ["heavy-oil"] = {type = "fluid", name = "heavy-oil"},
                ["light-oil"] = {type = "fluid", name = "light-oil"},
                ["petroleum-gas"] = {type = "fluid", name = "petroleum-gas"},
                steam = {type = "fluid", name = "steam"},
            },
            recipe = {
                ["coal-liquefaction"] = {
                    type = "recipe",
                    name = "coal-liquefaction",
                    ingredients = {
                        {"coal", 5},
                        {type = "fluid", name = "heavy-oil", amount = 10},
                        {type = "fluid", name = "steam", amount = 20},
                    },
                    results = {
                        {type = "fluid", name = "heavy-oil", amount = 100},
                        {type = "fluid", name = "light-oil", amount = 25},
                        {type = "fluid", name = "petroleum-gas", amount = 15},
                    },
                }
            },
        }
        prototype = gameScript.recipe_prototypes["coal-liquefaction"]
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
    end)

    local object
    before_each(function()
        object = RecipeTransform.make(prototype, intermediates)
    end)

    it(".make()", function()
        local coal = intermediates.item.coal
        local heavyOil = intermediates.fluid["heavy-oil"]
        local lightOil = intermediates.fluid["light-oil"]
        local gas = intermediates.fluid["petroleum-gas"]
        local steam = intermediates.fluid.steam

        local makeProductData = function(amount)
            return ProductData.make(ProductAmount.makeConstant(amount))
        end

        assert.are.same(object, {
            ingredients = {
                [coal] = 5,
                [heavyOil] = 10,
                [steam] = 20,
            },
            localisedName = {
                "dana.model.transform.name",
                {"dana.model.transform.recipeType"},
                prototype.localised_name,
            },
            products = {
                [heavyOil] = makeProductData(100),
                [lightOil] = makeProductData(25),
                [gas] = makeProductData(15),
            },
            rawRecipe = prototype,
            spritePath = "recipe/" .. prototype.name,
            type = "recipe",
        })
    end)

    it(".setmetatable", function()
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                object = object,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                RecipeTransform.setmetatable(objects.object)
            end,
        }
    end)
end)