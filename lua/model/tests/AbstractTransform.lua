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

local AbstractTransform = require("lua/model/AbstractTransform")
local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local ProductAmount = require("lua/model/ProductAmount")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("AbstractTransform", function()
    local gameScript
    local intermediates
    local MyMetatable
    local MyTransform

    setup(function()
        gameScript = LuaGameScript.make{
            fluid = {
                water = {
                    type = "fluid",
                    name = "water",
                },
            },
            item = {
                barrel = {
                    type = "item",
                    name = "barrel",
                },
                ["barreled-water"] = {
                    type = "item",
                    name = "barreled-water",
                },
                ["steel-plate"] = {
                    type= "item",
                    name = "steel-plate"
                },
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
        MyMetatable = {
            __index = {
                -- Implements AbstractTransform:generateSpritePath().
                generateSpritePath = function(self)
                    return "my-path/my-name"
                end,

                -- Implements AbstractTransform:getShortName().
                getShortName = function(self)
                    return {"my-name"}
                end,

                -- Implements AbstractTransform:getTypeStr().
                getTypeStr = function(self)
                    return {"MyType"}
                end,
            },
        }
        setmetatable(MyMetatable.__index, {__index = AbstractTransform.Metatable.__index})

        MyTransform = {
            new = function(object)
                local result = object or {}
                result.type = "MyType"
                return AbstractTransform.new(result, MyMetatable)
            end,
            setmetatable = function(object)
                AbstractTransform.setmetatable(object, MyMetatable)
            end,
        }
    end)

    it(".makeSpritePath()", function()
        local path = AbstractTransform.makeSpritePath("foo", {name = "bar"})
        assert.are.equals(path, "foo/bar")
    end)

    it(".makeTypeLocalisedStr", function()
        local typeStr = AbstractTransform.makeTypeLocalisedStr("MyType")
        assert.are.same(typeStr, {"dana.model.transform.MyType"})
    end)

    describe(".make()", function()
        local object
        before_each(function()
            object = MyTransform.new()
        end)

        it("-- spritePath", function()
            assert.are.equals(object.spritePath, "my-path/my-name")
        end)

        it("-- localisedName", function()
            assert.are.same(object.localisedName, {
                "dana.model.transform.name",
                {"MyType"},
                {"my-name"},
            })
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = MyTransform.new()
        end)

        it(":addIngredient()", function()
            local water = intermediates.fluid.water
            object:addIngredient(water, 10)
            assert.are.equals(object.ingredients[water], 10)
        end)

        it(":addProduct()", function()
            local steel = intermediates.item["steel-plate"]
            local amount = ProductAmount.makeConstant(7)
            object:addProduct(steel, amount)
            assert.are.same(object.products[steel], {
                count = 1,
                [1] = amount,
            })
        end)

        it(":addRawIngredientArray()", function()
            local barrel = intermediates.item.barrel
            local water = intermediates.fluid.water
            object:addRawIngredientArray(intermediates, {
                {type = "item", name = "barrel", amount = 1},
                {type = "fluid", name = "water", amount = 10},
            })
            assert.are.equals(object.ingredients[water], 10)
            assert.are.equals(object.ingredients[barrel], 1)
        end)

        it(":addRawProduct()", function()
            local barrel = intermediates.item.barrel
            object:addRawProduct(intermediates, {
                type = "item",
                name = "barrel",
                amount = 5,
                probability = 0.75,
            })
            assert.are.same(object.products[barrel], {
                count = 1,
                [1] = {
                    amountMax = 5,
                    amountMin = 5,
                    probability = 0.75,
                },
            })
        end)

        it(":addRawProductArray()", function()
            object:addRawProductArray(intermediates, {
                {type = "item", name = "barrel", amount = 1},
                {type = "fluid", name = "water", amount_max = 5, amount_min = 1, probability = 0.75},
                {type = "item", name = "barrel", amount = 2},
            })
            assert.are.same(object.products[intermediates.fluid.water], {
                count = 1,
                [1] = {amountMax = 5, amountMin = 1, probability = 0.75},
            })
            assert.are.same(object.products[intermediates.item.barrel], {
                count = 2,
                [1] = {amountMax = 1, amountMin = 1, probability = 1},
                [2] = {amountMax = 2, amountMin = 2, probability = 1},
            })
        end)

        describe(".setmetatable()", function()
            local steel = intermediates.item["steel-plate"]
            local barrel = intermediates.item.barrel
            object:addIngredient(steel, 5)
            object:addProduct(barrel, ProductAmount.makeConstant(1))
            SaveLoadTester.run{
                objects = {
                    intermediates = intermediates,
                    transform = object,
                },
                metatableSetter = function(objects)
                    IntermediatesDatabase.setmetatable(objects.intermediates)
                    MyTransform.setmetatable(objects.transform)
                end,
            }
        end)
    end)

    describe(":isNonPositiveCycleWith()", function()
        local filling
        local emptying

        before_each(function()
            filling = MyTransform.new()
            filling:addRawIngredientArray(intermediates, {
                {type = "item", name = "barrel", amount = 10},
                {type = "fluid", name = "water", amount = 100},
            })
            filling:addRawProduct(intermediates, {type = "item", name = "barreled-water", amount = 10})

            emptying = MyTransform.new()
        end)

        it("--valid", function()
            emptying:addRawIngredientArray(intermediates, {
                {type = "item", name = "barreled-water", amount = 10},
            })
            emptying:addRawProductArray(intermediates, {
                {type = "item", name = "barrel", amount = 10},
                {type = "fluid", name = "water", amount = 150, probability = 0.5},
            })
            assert.is_true(filling:isNonPositiveCycleWith(emptying))
            assert.is_true(emptying:isNonPositiveCycleWith(filling))
        end)

        it("-- positive", function()
            emptying:addRawIngredientArray(intermediates, {
                {type = "item", name = "barreled-water", amount = 10},
            })
            emptying:addRawProductArray(intermediates, {
                {type = "item", name = "barrel", amount = 1},
                {type = "fluid", name = "water", amount = 101},
            })
            assert.is_false(filling:isNonPositiveCycleWith(emptying))
            assert.is_false(emptying:isNonPositiveCycleWith(filling))
        end)

        it("-- set mismatch", function()
            emptying:addRawIngredientArray(intermediates, {
                {type = "item", name = "barreled-water", amount = 10},
                {type = "item", name = "steel-plate", amount = 1},
            })
            emptying:addRawProductArray(intermediates, {
                {type = "item", name = "barrel", amount = 10},
                {type = "fluid", name = "water", amount = 100},
            })
            assert.is_false(filling:isNonPositiveCycleWith(emptying))
            assert.is_false(emptying:isNonPositiveCycleWith(filling))
        end)
    end)
end)
