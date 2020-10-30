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

local BoilerTransform = require("lua/model/BoilerTransform")
local FuelTransform = require("lua/model/FuelTransform")
local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local OffshorePumpTransform = require("lua/model/OffshorePumpTransform")
local RecipeTransform = require("lua/model/RecipeTransform")
local ResourceTransform = require("lua/model/ResourceTransform")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TransformsDatabase = require("lua/model/TransformsDatabase")

describe("TransformsDatabase", function()
    local gameScript
    local intermediates
    setup(function()
        gameScript = LuaGameScript.make{
            boiler = {
                myBoiler = {
                    type = "boiler",
                    name = "myBoiler",
                    energy_source = {
                        type = "void",
                    },
                    fluid_box = {
                        production_type = "input-output",
                        filter = "water",
                    },
                    output_fluid_box = {
                        production_type = "output",
                        filter = "steam",
                    },
                },
            },
            fluid = {
                steam = {type = "fluid", name = "steam"},
                water = {type = "fluid", name = "water"},
            },
            item = {
                ash = {type = "item", name = "ash"},
                barrel = {type = "item", name = "barrel"},
                ["barreled-water"] = {type = "item", name = "barreled-water"},
                wood = {
                    type = "item",
                    name = "wood",
                    burnt_result = "ash",
                },
            },
            ["offshore-pump"] = {
                well = {
                    type = "offshore-pump",
                    name = "well",
                    fluid = "water",
                    fluid_box = {
                        type = "output",
                        filter = "water",
                    },
                    pumping_speed = 2,
                },
            },
            recipe = {
                ["fill-water-barrel"] = {
                    type = "recipe",
                    name = "fill-water-barrel",
                    ingredients = {
                        {"barrel", 1},
                        {type = "fluid", name = "water", amount = 10},
                    },
                    result = "barreled-water",
                },
            },
            resource = {
                ["wood-ore"] = {
                    type = "resource",
                    name = "wood-ore",
                    minable = {
                        result = "wood",
                        count = 5,
                    },
                },
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
    end)

    it(".new()", function()
        local database = TransformsDatabase.new{
            intermediates = intermediates,
        }
        assert.is_not_nil(database.boiler)
        assert.is_not_nil(database.fuel)
        assert.is_not_nil(database.offshorePump)
        assert.is_not_nil(database.recipe)
        assert.is_not_nil(database.resource)
        assert.is_not_nil(database.producersOf)
        assert.is_not_nil(database.consumersOf)
    end)

    it(":rebuild()", function()
        local transforms = TransformsDatabase.new{
            intermediates = intermediates,
        }
        transforms:rebuild(gameScript)

        local myBoiler = gameScript.entity_prototypes.myBoiler
        local well = gameScript.entity_prototypes.well
        local barreling = gameScript.recipe_prototypes["fill-water-barrel"]
        local woodOre = gameScript.entity_prototypes["wood-ore"]
        assert.are.same(transforms, {
            intermediates = intermediates,
            boiler = {
                myBoiler = BoilerTransform.tryMake(myBoiler, intermediates),
            },
            fuel = {
                wood = FuelTransform.tryMake(intermediates.item.wood, intermediates),
            },
            offshorePump = {
                well = OffshorePumpTransform.make(well, intermediates),
            },
            recipe = {
                ["fill-water-barrel"] = RecipeTransform.make(barreling, intermediates),
            },
            resource = {
                ["wood-ore"] = ResourceTransform.tryMake(woodOre, intermediates),
            },
            consumersOf = {
                [intermediates.fluid.water] = {
                    [transforms.recipe["fill-water-barrel"]] = true,
                    [transforms.boiler.myBoiler] = true,
                },
                [intermediates.item.wood] = {[transforms.fuel.wood] = true},
                [intermediates.item.barrel] = {[transforms.recipe["fill-water-barrel"]] = true},
            },
            producersOf = {
                [intermediates.fluid.steam] = {[transforms.boiler.myBoiler] = true},
                [intermediates.item.ash] = {[transforms.fuel.wood] = true},
                [intermediates.fluid.water] = {[transforms.offshorePump.well] = true},
                [intermediates.item.wood] = {[transforms.resource["wood-ore"]] = true},
                [intermediates.item["barreled-water"]] = {[transforms.recipe["fill-water-barrel"]] = true},
            },
        })
    end)

    it(".setmetatable()", function()
        local transforms = TransformsDatabase.new{
            intermediates = intermediates,
        }
        transforms:rebuild(gameScript)
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                transforms = transforms,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                TransformsDatabase.setmetatable(objects.transforms)
            end,
        }
    end)
end)
