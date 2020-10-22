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

local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaGameScript", function()
    local rawData = {
        fluid = {
            steam = {
                type = "fluid",
                name = "steam",
            },
            water = {
                type = "fluid",
                name = "water",
            },
        },
        item = {
            wood = {
                type = "item",
                name = "wood",
            },
        },
        recipe = {
            boiling = {
                type = "recipe",
                name = "boiling",
                expensive = {
                    ingredients = {
                        {type = "fluid", name = "water", amount = 10},
                    },
                    results = {
                        {type = "fluid", name = "steam", amount = 10},
                    },
                },
            },
        },
        resource = {
            ["wood-ore"] = {
                type = "resource",
                name = "wood-ore",
                minable = {
                    result = "wood",
                    count = 5,
                    required_fluid = "steam",
                },
            },
        },
    }
    local gameScript

    before_each(function()
        gameScript = LuaGameScript.make(rawData)
    end)

    describe(".make()", function()
        it("-- fluid_prototypes", function()
            local data = MockObject.getDataIfValid(gameScript)

            local water = data.fluid_prototypes.water
            assert.are.equals(water.name, "water")
            assert.are.equals(getmetatable(water).className, "LuaFluidPrototype")

            local wood = data.item_prototypes.wood
            assert.are.equals(wood.name, "wood")
            assert.are.equals(getmetatable(wood).className, "LuaItemPrototype")
        end)

        describe("-- recipe_prototypes", function()
            it(", valid", function()
                local data = MockObject.getData(gameScript)

                local boiling = data.recipe_prototypes.boiling
                assert.are.equals(boiling.name, "boiling")
                assert.are.equals(getmetatable(boiling).className, "LuaRecipePrototype")
                assert.are.equals(boiling.ingredients[1].name, "water")
                assert.are.equals(boiling.products[1].name, "steam")
            end)

            it(", invalid ingredient", function()
                assert.error(function()
                    LuaGameScript.make{
                        item = rawData.item,
                        fluid = rawData.fluid,
                        recipe = {
                            wrongIngredient = {
                                type = "recipe",
                                name = "wrongIngredient",
                                ingredients = {
                                    {type = "item", name = "HTTP404", amount = 1},
                                },
                                results = {
                                    {type = "item", name = "wood", amount = 2},
                                },
                            },
                        },
                    }
                end)
            end)

            it(", invalid product", function()
                assert.error(function()
                    LuaGameScript.make{
                        item = rawData.item,
                        fluid = rawData.fluid,
                        recipe = {
                            wrongIngredient = {
                                type = "recipe",
                                name = "wrongIngredient",
                                ingredients = {
                                    {type = "item", name = "wood", amount = 2},
                                },
                                results = {
                                    {type = "item", name = "HTTP404", amount = 1},
                                },
                            },
                        },
                    }
                end)
            end)
        end)

        describe("-- resource prototype", function()
            it(", valid", function()
                local data = MockObject.getData(gameScript)

                local woodOre = data.entity_prototypes["wood-ore"]
                assert.are.equals(woodOre.name, "wood-ore")
                assert.are.equals(getmetatable(woodOre).className, "LuaEntityPrototype")
                assert.are.same(woodOre.mineable_properties, {
                    fluid_amount = 0,
                    minable = true,
                    products = {
                        {type = "item", name = "wood", amount = 5},
                    },
                    required_fluid = "steam",
                })
            end)

            it(", invalid mining fluid", function()
                assert.error(function()
                    LuaGameScript.make{
                        item = rawData.item,
                        fluid = rawData.fluid,
                        resource = {
                            sample = {
                                type = "resource",
                                name = "sample",
                                minable = {
                                    required_fluid = "HTTP404",
                                },
                            },
                        },
                    }
                end)
            end)

            it(", invalid product", function()
                assert.error(function()
                    LuaGameScript.make{
                        item = rawData.item,
                        fluid = rawData.fluid,
                        resource = {
                            sample = {
                                type = "resource",
                                name = "sample",
                                minable = {
                                    results = {
                                        {"HTTP404", 4},
                                    },
                                },
                            },
                        },
                    }
                end)
            end)
        end)
    end)

    describe(":fluid_prototypes", function()
        it("-- read", function()
            local water = gameScript.fluid_prototypes.water
            assert.are.equals(water.name, "water")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.fluid_prototypes.water = "denied"
            end)
        end)
    end)

    describe(":item_prototypes", function()
        it("-- read", function()
            local wood = gameScript.item_prototypes.wood
            assert.are.equals(wood.name, "wood")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.item_prototypes.wood = "denied"
            end)
        end)
    end)

    describe(":recipe_prototypes", function()
        it("-- read", function()
            local boiling = gameScript.recipe_prototypes.boiling
            assert.are.equals(boiling.name, "boiling")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.recipe_prototypes.boiling = "denied"
            end)
        end)
    end)

    describe(":entity_prototypes", function()
        it("-- read", function()
            local woodOre = gameScript.entity_prototypes["wood-ore"]
            assert.are.equals(woodOre.name, "wood-ore")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.entity_prototypes["wood-ore"] = "denied"
            end)
        end)
    end)
end)
