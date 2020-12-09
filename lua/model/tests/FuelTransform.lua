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

local FuelTransform = require("lua/model/FuelTransform")
local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TransformMaker = require("lua/model/TransformMaker")

describe("FuelTransform", function()
    local gameScript
    local intermediates
    local maker
    setup(function()
        gameScript = LuaGameScript.make{
            item = {
                ash = {type = "item", name = "ash"},
                coal = {type = "item", name = "coal", burnt_result = "ash"},
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)

        maker = TransformMaker.new{
            intermediates = intermediates,
        }
    end)

    local getAmount = function(productAmount)
        return maker.productAmountFactory:get(productAmount)
    end

    describe(".tryMake()", function()
        it("-- burnt_result", function()
            local ash = intermediates.item.ash
            local coal = intermediates.item.coal
            local object = FuelTransform.tryMake(maker, coal)
            assert.are.same(object, {
                ingredients = {
                    [coal] = 1,
                },
                inputItem = coal,
                localisedName = {
                    "dana.model.transform.name",
                    {"dana.model.transform.fuelType"},
                    coal.rawPrototype.localised_name,
                },
                products = {
                    [ash] = ProductData.make(getAmount(ProductAmount.makeConstant(1))),
                },
                type = "fuel",
                spritePath = ash.spritePath,
            })
        end)

        it("-- no burnt_result", function()
            local ash = intermediates.item.ash
            local object = FuelTransform.tryMake(maker, ash)
            assert.is_nil(object)
        end)
    end)

    describe(".setmetatable()", function()
        local object = FuelTransform.tryMake(maker, intermediates.item.coal)
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                object = object,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                FuelTransform.setmetatable(objects.object)
            end,
        }
    end)
end)
