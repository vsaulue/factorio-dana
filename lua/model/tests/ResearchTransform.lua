-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local ResearchTransform = require("lua/model/ResearchTransform")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TransformMaker = require("lua/model/TransformMaker")

describe("RecipeTransform", function()
    local gameScript
    local intermediates
    local maker
    local prototype
    setup(function()
        gameScript = LuaGameScript.make{
            technology = {
                automation1 = {
                    type = "technology",
                    name = "automation1",
                },
                automation2 = {
                    type = "technology",
                    name = "automation2",
                    prerequisites = {"automation1"},
                },
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
        prototype = gameScript.technology_prototypes.automation2

        maker = TransformMaker.new{
            intermediates = intermediates,
        }
    end)

    local object
    before_each(function()
        object = ResearchTransform.make(maker, prototype)
    end)

    it(".make()", function()
        local i_automation1 = intermediates.technology.automation1
        local i_automation2 = intermediates.technology.automation2

        local makeProductData = function(amount)
            local internedAmount = maker.productAmountFactory:get(ProductAmount.makeConstant(amount))
            return ProductData.make(internedAmount)
        end

        assert.are.same(object, {
            ingredients = {
                [i_automation1] = 1,
            },
            localisedName = {
                "dana.model.transform.name",
                {"dana.model.transform.researchType"},
                prototype.localised_name,
            },
            products = {
                [i_automation2] = makeProductData(1),
            },
            rawTechnology = prototype,
            spritePath = "technology/" .. prototype.name,
            type = "research",
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
                ResearchTransform.setmetatable(objects.object)
            end,
        }
    end)
end)