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
local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local SimpleCyclesDatabase = require("lua/model/SimpleCyclesDatabase")
local TransformsDatabase = require("lua/model/TransformsDatabase")

describe("SimpleCyclesDatabase", function()
    local gameScript
    local intermediates
    local transforms
    setup(function()
        gameScript = LuaGameScript.make{
            fluid = {
                water = {type = "fluid", name = "water"},
            },
            item = {
                barrel = {type = "item", name = "barrel"},
                steel = {type = "item", name = "steel"},
                filledBarrel = {type = "item", name = "filledBarrel"},
            },
            recipe = {
                barrel = {
                    type = "recipe",
                    name = "barrel",
                    ingredients = {
                        {"steel", 5},
                    },
                    results = {
                        {"barrel", 1},
                    },
                },
                filling = {
                    type = "recipe",
                    name = "filling",
                    ingredients = {
                        {"barrel", 1},
                        {type = "fluid", name = "water", amount = 10},
                    },
                    results = {
                        {"filledBarrel", 1},
                    },
                },
                magicEmptying = {
                    type = "recipe",
                    name = "magicEmptying",
                    ingredients = {
                        {"filledBarrel", 1},
                    },
                    results = {
                        {"barrel", 1},
                        {type = "fluid", name = "water", amount = 11},
                    },
                },
                lossyEmptying = {
                    type = "recipe",
                    name = "lossyEmptying",
                    ingredients = {
                        {"filledBarrel", 1},
                    },
                    results = {
                        {"barrel", 1},
                        {type = "fluid", name = "water", amount = 11, probability = 0.9},
                    },
                },
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
        transforms = TransformsDatabase.new{
            intermediates = intermediates,
        }
        transforms:rebuild(gameScript)
    end)

    local cycles
    before_each(function()
        cycles = SimpleCyclesDatabase.new{
            transforms = transforms,
        }
    end)

    it(".new()", function()
        assert.is_not_nil(cycles.nonPositive)
    end)

    it(":rebuild()", function()
        cycles:rebuild()
        local lossyEmptying = transforms.recipe.lossyEmptying
        local filling = transforms.recipe.filling
        assert.are.same(cycles, {
            nonPositive = {
                [lossyEmptying] = {
                    [filling] = true,
                },
                [filling] = {
                    [lossyEmptying] = true,
                },
            },
            transforms = transforms,
        })
    end)

    it(".setmetatable()", function()
        cycles:rebuild()
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                transforms = transforms,
                cycles = cycles,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                TransformsDatabase.setmetatable(objects.transforms)
                SimpleCyclesDatabase.setmetatable(objects.cycles)
            end,
        }
    end)
end)
