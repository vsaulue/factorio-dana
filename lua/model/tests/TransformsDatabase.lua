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
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local Set = require("lua/containers/Set")
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

    local transforms
    before_each(function()
        transforms = TransformsDatabase.new{
            intermediates = intermediates,
        }
    end)

    it(".new()", function()
        assert.is_not_nil(transforms.boiler)
        assert.is_not_nil(transforms.fuel)
        assert.is_not_nil(transforms.offshorePump)
        assert.is_not_nil(transforms.recipe)
        assert.is_not_nil(transforms.resource)
        assert.is_not_nil(transforms.producersOf)
        assert.is_not_nil(transforms.consumersOf)
    end)

    it(":forEach()", function()
        transforms:rebuild(gameScript)
        local set = {}
        transforms:forEach(function(transform)
            assert.is_nil(set[transform])
            set[transform] = true
        end)
        assert.are.same(set, Set.fromArray{
            transforms.boiler.myBoiler,
            transforms.fuel.wood,
            transforms.offshorePump.well,
            transforms.recipe["fill-water-barrel"],
            transforms.resource["wood-ore"],
        })
    end)

    it(":rebuild()", function()
        transforms:rebuild(gameScript)

        assert.are.same(transforms.consumersOf, {
            [intermediates.fluid.water] = {
                [transforms.recipe["fill-water-barrel"]] = true,
                [transforms.boiler.myBoiler] = true,
            },
            [intermediates.item.wood] = {[transforms.fuel.wood] = true},
            [intermediates.item.barrel] = {[transforms.recipe["fill-water-barrel"]] = true},
        })
        assert.are.same(transforms.producersOf, {
            [intermediates.fluid.steam] = {[transforms.boiler.myBoiler] = true},
            [intermediates.item.ash] = {[transforms.fuel.wood] = true},
            [intermediates.fluid.water] = {[transforms.offshorePump.well] = true},
            [intermediates.item.wood] = {[transforms.resource["wood-ore"]] = true},
            [intermediates.item["barreled-water"]] = {[transforms.recipe["fill-water-barrel"]] = true},
        })
    end)

    it(".setmetatable()", function()
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
