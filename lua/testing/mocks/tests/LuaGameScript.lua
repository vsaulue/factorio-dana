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
        boiler = {
            myBoiler = {
                type = "boiler",
                name = "myBoiler",
                energy_source = {
                    type = "void",
                },
                fluid_box = {
                    production_type = "input",
                    filter = "water",
                },
                output_fluid_box = {
                    production_type = "output",
                    filter = "steam",
                },
            },
        },
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
            ash = {
                type = "item",
                name = "ash",
            },
            wood = {
                type = "item",
                name = "wood",
                burnt_result = "ash",
            },
        },
        ["offshore-pump"] = {
            ["water-pump"] = {
                type = "offshore-pump",
                name = "water-pump",
                fluid = "water",
                fluid_box = {
                    filter = "water",
                    production_type = "output"
                },
                pumping_speed = 10,
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

    it(".createPlayer()", function()
        local player = LuaGameScript.createPlayer(gameScript, {
            forceName = "player",
        })
        local gameData = MockObject.getData(gameScript)
        assert.are.equals(player.force, gameData.forces.player)
        assert.are.equals(player, gameData.players[player.index])
    end)

    describe(".make()", function()
        describe("-- boiler prototypes", function()
            it(", valid", function()
                local data = MockObject.getData(gameScript)
                local boiler = data.entity_prototypes.myBoiler
                local water = data.fluid_prototypes.water
                local steam = data.fluid_prototypes.steam
                assert.are.equals(boiler.name, "myBoiler")
                assert.are.equals(getmetatable(boiler).className, "LuaEntityPrototype")
                assert.are.same(boiler.fluidbox_prototypes, {
                    MockObject.make{production_type = "input", filter = water},
                    MockObject.make{production_type = "output", filter = steam},
                })
            end)

            it(", invalid filter", function()
                assert.error(function()
                    LuaGameScript.make{
                        boiler = {
                            myBoiler = {
                                type = "boiler",
                                name = "myBoiler",
                                energy_source = {
                                    type = "void",
                                },
                                fluid_box = {
                                    production_type = "input",
                                    filter = "HTTP404",
                                },
                                output_fluid_box = {
                                    production_type = "output",
                                    filter = "steam",
                                },
                            },
                        },
                        fluid = rawData.fluid,
                    }
                end)
            end)
        end)

        it("-- fluid_prototypes", function()
            local data = MockObject.getDataIfValid(gameScript)

            local water = data.fluid_prototypes.water
            assert.are.equals(water.name, "water")
            assert.are.equals(getmetatable(water).className, "LuaFluidPrototype")
        end)

        it("-- default forces", function()
            local data = MockObject.getData(gameScript)
            assert.is_not_nil(data.forces.player)
            assert.are.equals(getmetatable(data.forces.player).className, "LuaForce")
        end)

        describe("-- item_prototypes", function()
            it(", valid", function()
                local data = MockObject.getDataIfValid(gameScript)

                local wood = data.item_prototypes.wood
                assert.are.equals(wood.name, "wood")
                assert.are.equals(getmetatable(wood).className, "LuaItemPrototype")
                assert.are.equals(wood.burnt_result, data.item_prototypes.ash)
            end)

            it(", invalid burnt_result", function()
                assert.error(function()
                    LuaGameScript.make{
                        item = {
                            wood = {
                                type = "item",
                                name = "wood",
                                burnt_result = "smoke",
                            },
                        },
                    }
                end)
            end)
        end)

        describe("-- offshore-pump prototypes", function()
            it(", valid", function()
                local data = MockObject.getData(gameScript)

                local waterPump = data.entity_prototypes["water-pump"]
                assert.are.equals(waterPump.name, "water-pump")
                assert.are.equals(getmetatable(waterPump).className, "LuaEntityPrototype")
                assert.are.equals(waterPump.fluid, data.fluid_prototypes.water)
                assert.are.equals(waterPump.pumping_speed, 10)
                assert.are.same(waterPump.fluidbox_prototypes[1], MockObject.make{
                    filter = data.fluid_prototypes.water,
                    production_type = "output",
                })
            end)

            it(", invalid fluid", function()
                assert.error(function()
                    LuaGameScript.make{
                        fluid = rawData.fluid,
                        ["offshore-pump"] = {
                            ["water-pump"] = {
                                type = "offshore-pump",
                                name = "water-pump",
                                fluid = "HTTP404",
                                fluid_box = {
                                    filter = "water",
                                    production_type = "output"
                                },
                                pumping_speed = 10,
                            },
                        },
                    }
                end)
            end)

            it(", invalid pumping_speed", function()
                assert.error(function()
                    LuaGameScript.make{
                        fluid = rawData.fluid,
                        ["offshore-pump"] = {
                            ["water-pump"] = {
                                type = "offshore-pump",
                                name = "water-pump",
                                fluid = "water",
                                fluid_box = {
                                    filter = "water",
                                    production_type = "output"
                                },
                                pumping_speed = "denied",
                            },
                        },
                    }
                end)
            end)
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

    it(":create_force()", function()
        local force = gameScript.create_force("foobar")
        assert.are.equals(getmetatable(force).className, "LuaForce")
        assert.are.equals(force.recipes.boiling.prototype.name, "boiling")
        assert.are.equals(MockObject.getData(gameScript).forces.foobar, force)
    end)

    it(":create_surface()", function()
        local surface = gameScript.create_surface("Isengard", {})
        assert.are.equals(getmetatable(surface).className, "LuaSurface")
        assert.are.equals(MockObject.getData(gameScript).surfaces[surface.name], surface)
        assert.are.equals(surface.index, 1)
        assert.are.equals(surface.name, "Isengard")
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

    describe(":forces", function()
        it("-- read", function()
            MockObject.getData(gameScript).forces.foo = "bar"
            assert.are.equals(gameScript.forces.foo, "bar")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.forces.foobar = "denied"
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

    describe(":players", function()
        it("-- read", function()
            assert.are.equals(MockObject.getData(gameScript.players), MockObject.getData(gameScript).players)
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.players.kilroy = "denied"
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

    it(":surfaces", function()
        assert.are.equals(MockObject.getData(gameScript).surfaces, MockObject.getData(gameScript.surfaces))
    end)
end)
