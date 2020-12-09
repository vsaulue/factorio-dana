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
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local ProductAmount = require("lua/model/ProductAmount")
local TransformMaker = require("lua/model/TransformMaker")

describe("TransformMaker", function()
    local constant = ProductAmount.makeConstant
    local factorio
    local intermediates
    setup(function()
        factorio = MockFactorio.make{
            rawData = {
                fluid = {
                    steam = {type = "fluid", name = "steam"},
                    water = {type = "fluid", name = "water"},
                },
                item = {
                    wood = {type = "item", name = "wood"},
                    coal ={type = "item", name = "coal"},
                },
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(factorio.game)
    end)

    local context
    local factory
    before_each(function()
        context = TransformMaker.new{
            intermediates = intermediates,
        }
        factory = context.productAmountFactory
    end)

    it(":addConstantProduct()", function()
        context:newTransform()
        context:addConstantProduct("item", "coal", 5)
        assert.are.same(context.transform.products, {
            [intermediates.item.coal] = {
                [factory:get(constant(5))] = 1,
            },
        })
    end)

    it(":addIngredient()", function()
        context:newTransform()
        context:addIngredient("fluid", "water", 8)
        assert.are.same(context.transform.ingredients, {
            [intermediates.fluid.water] = 8,
        })
    end)

    it("addIngredientIntermediate()", function()
        context:newTransform()
        context:addIngredientIntermediate(intermediates.item.coal, 3)
        assert.are.same(context.transform.ingredients, {
            [intermediates.item.coal] = 3,
        })
    end)

    it(":addRawIngredientArray", function()
        context:newTransform()
        context:addRawIngredientArray{
            {type = "item", name = "wood", amount = 5},
            {type = "fluid", name = "water", amount = 3},
            {type = "item", name = "wood", amount = 2},
        }
        assert.are.same(context.transform.ingredients, {
            [intermediates.item.wood] = 7,
            [intermediates.fluid.water] = 3,
        })
    end)

    it(":addRawProduct", function()
        context:newTransform()
        context:addRawProduct({
            type = "fluid",
            name = "water",
            amount_max = 5,
            amount_min = 3,
            probability = 0.25,
        })
        assert.are.same(context.transform.products, {
            [intermediates.fluid.water] = {
                [factory:get{amountMax = 5, amountMin = 3, probability = 0.25}] = 1,
            },
        })
    end)

    it(":addRawProductArray()", function()
        context:newTransform{}
        context:addRawProductArray{
            {type = "item", name = "coal", amount = 1},
            {type = "fluid", name = "water", amount_max = 2, amount_min = 1, probability = 0.5},
            {type = "item", name = "coal", amount = 2},
        }
        assert.are.same(context.transform.products, {
            [intermediates.item.coal] = {
                [factory:get(constant(1))] = 1,
                [factory:get(constant(2))] = 1,
            },
            [intermediates.fluid.water] = {
                [factory:get{amountMax = 2, amountMin = 1, probability = 0.5}] = 1,
            },
        })
    end)

    it(":newTransform()", function()
        local result = context:newTransform()
        assert.is_not_nil(result)
        assert.are.equals(result, context.transform)
    end)
end)
