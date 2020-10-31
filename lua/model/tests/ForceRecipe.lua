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

local ForceRecipe = require("lua/model/ForceRecipe")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ForceRecipe", function()
    local gameScript
    local prototypes
    setup(function()
        gameScript = LuaGameScript.make{
            fluid = {
                air = {type = "fluid", name = "air"},
            },
            recipe = {
                air = {
                    type = "recipe",
                    name = "air",
                    ingredients = {},
                    results = {
                        {type = "fluid", name = "air", amount = 10},
                    },
                },
            },
        }
        gameScript.create_force("beWithYou")
        prototypes = PrototypeDatabase.new(gameScript)
    end)

    local object
    before_each(function()
        object = ForceRecipe.make(gameScript.recipe_prototypes.air, prototypes.transforms)
    end)

    it(".new()", function()
        assert.are.same(object, {
            rawRecipe = gameScript.recipe_prototypes.air,
            recipeTransform = prototypes.transforms.recipe.air,
        })
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = {
                prototypes = prototypes,
                object = object,
            },
            metatableSetter = function(objects)
                PrototypeDatabase.setmetatable(objects.prototypes)
                ForceRecipe.setmetatable(objects.object)
            end,
        }
    end)
end)
