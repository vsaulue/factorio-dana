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

local LuaRecipePrototype = require("lua/testing/mocks/LuaRecipePrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaRecipePrototype", function()
    local rawCoalLiquefactionData = {
        ingredients = {
            {"coal", 1},
            {type = "fluid", name = "steam", amount = 10},
            {type = "fluid", name = "heavy-oil", amount = 20},
        },
        results = {
            {type = "fluid", name = "heavy-oil", amount = 100},
            {type = "fluid", name = "light-oil", amount = 20, probability = 0.75},
            {type = "fluid", name = "petroleum-gas", amount_min = 10, amount_max = 15},
        },
    }
    local rawWireData = {
        ingredients = {
            {"copper", 1},
        },
        result = "copper-wire",
        result_count = 2,
    }

    describe(".make()", function()
        it("-- valid, normal + expensive", function()
            local recipe = LuaRecipePrototype.make{
                type = "recipe",
                name = "coal-liquefaction",
                normal = rawCoalLiquefactionData,
                expensive = rawWireData,
                result = "yolo",
                result_count = 666,
            }
            assert.are.same(MockObject.getData(recipe), {
                type = "recipe",
                name = "coal-liquefaction",
                localised_name = {"recipe-name.coal-liquefaction"},
                ingredients = {
                    {type = "item", name = "coal", amount = 1},
                    {type = "fluid", name = "steam", amount = 10},
                    {type = "fluid", name = "heavy-oil", amount = 20},
                },
                products = {
                    {type = "fluid", name = "heavy-oil", amount = 100},
                    {type = "fluid", name = "light-oil", amount = 20, probability = 0.75},
                    {type = "fluid", name = "petroleum-gas", amount_min = 10, amount_max = 15},
                },
            })
        end)

        it("-- valid, expensive", function()
            local recipe = LuaRecipePrototype.make{
                type = "recipe",
                name = "copper-wire",
                expensive = rawWireData,
            }
            assert.are.same(MockObject.getData(recipe), {
                type = "recipe",
                name = "copper-wire",
                localised_name = {"recipe-name.copper-wire"},
                ingredients = {
                    {type = "item", name = "copper", amount = 1},
                },
                products = {
                    {type = "item", name = "copper-wire", amount = 2},
                },
            })
        end)

        it("-- valid, no difficulty", function()
            local recipe = LuaRecipePrototype.make{
                type = "recipe",
                name = "iron-gear",
                ingredients = {
                    {"iron-plate", 2},
                },
                result = "iron-gear",
            }
            assert.are.same(MockObject.getData(recipe), {
                type = "recipe",
                name = "iron-gear",
                localised_name = {"recipe-name.iron-gear"},
                ingredients = {
                    {type = "item", name = "iron-plate", amount = 2},
                },
                products = {
                    {type = "item", name = "iron-gear", amount = 1},
                },
            })
        end)

        it("-- invalid type", function()
            assert.error(function()
                LuaRecipePrototype.make{
                    type = "RECIPE",
                    name = "copper-wire",
                    normal = rawWireData,
                }
            end)
        end)
    end)

    describe("", function()
        local recipe
        before_each(function()
            recipe = LuaRecipePrototype.make{
                type = "recipe",
                name = "coal-liquefaction",
                normal = rawCoalLiquefactionData,
            }
        end)

        it(":ingredients", function()
            local fromData = MockObject.getData(recipe).ingredients
            local ingredients = recipe.ingredients
            assert.are.same(ingredients, fromData)
            assert.are_not.equals(ingredients,fromData)
            for k,v in pairs(ingredients) do
                assert.are_not.equals(v, fromData[k])
            end
        end)

        it(":products", function()
            local fromData = MockObject.getData(recipe).products
            local products = recipe.products
            assert.are.same(products, fromData)
            assert.are_not.equals(products,fromData)
            for k,v in pairs(products) do
                assert.are_not.equals(v, fromData[k])
            end
        end)
    end)
end)
