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
local TransformMaker = require("lua/model/TransformMaker")

describe("AbstractTransform", function()
    local gameScript
    local intermediates
    local maker
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
        intermediates = IntermediatesDatabase.new(maker)
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

        maker = TransformMaker.new{
            intermediates = intermediates,
        }

        MyTransform = {
            new = function(maker, ingredients, products)
                maker:newTransform{
                    type = "MyType",
                }
                if ingredients then
                    maker:addRawIngredientArray(ingredients)
                end
                if products then
                    maker:addRawProductArray(products)
                end
                return AbstractTransform.make(maker, MyMetatable)
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
            object = MyTransform.new(maker)
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

    it(".setmetatable()", function()
        local ingredients = {
            {type = "item", name = "steel-plate", amount = 5},
        }
        local products = {
            {type = "item", name = "barrel", amount = 1},
        }
        local object = MyTransform.new(maker, ingredients, products)
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

    describe(":getSinkType()", function()
        it("-- normal", function()
            local transform = MyTransform.new(maker, {
                {type = "item", name = "barrel", amount = 1},
            })
            assert.are.equals(transform:getSinkType(), "normal")
        end)

        it("-- recursive", function()
            local transform = MyTransform.new(maker, {
                {type = "item", name = "barrel", amount = 2},
            },{
                {type = "item", name = "barrel", amount_min = 1, amount_max = 2},
            })
            assert.are.equals(transform:getSinkType(), "recursive")
        end)

        it("-- none (positive loop)", function()
            local transform = MyTransform.new(maker, {
                {type = "item", name = "barrel", amount = 2},
            },{
                {type = "item", name = "barrel", amount = 3},
            })
            assert.are.equals(transform:getSinkType(), "none")
        end)

        it("-- none (source)", function()
            local transform = MyTransform.new(maker, {}, {
                {type = "item", name = "barrel", amount = 1},
            })
            assert.are.equals(transform:getSinkType(), "none")
        end)
    end)

    describe(":isNonPositiveCycleWith()", function()
        local filling
        local ingredients
        local products

        before_each(function()
            ingredients = {
                {type = "item", name = "barrel", amount = 10},
                {type = "fluid", name = "water", amount = 100},
            }
            products = {
                {type = "item", name = "barreled-water", amount = 10},
            }
            filling = MyTransform.new(maker, ingredients, products)
        end)

        it("--valid", function()
            local emptying = MyTransform.new(maker, products, {
                {type = "item", name = "barrel", amount = 10},
                {type = "fluid", name = "water", amount = 150, probability = 0.5},
            })
            assert.is_true(filling:isNonPositiveCycleWith(emptying))
            assert.is_true(emptying:isNonPositiveCycleWith(filling))
        end)

        it("-- positive", function()
            local emptying = MyTransform.new(maker, products, {
                {type = "item", name = "barrel", amount = 1},
                {type = "fluid", name = "water", amount = 101},
            })
            assert.is_false(filling:isNonPositiveCycleWith(emptying))
            assert.is_false(emptying:isNonPositiveCycleWith(filling))
        end)

        it("-- set mismatch", function()
            local emptying = MyTransform.new(maker, {
                {type = "item", name = "barreled-water", amount = 10},
                {type = "item", name = "steel-plate", amount = 1},
            }, ingredients)
            assert.is_false(filling:isNonPositiveCycleWith(emptying))
            assert.is_false(emptying:isNonPositiveCycleWith(filling))
        end)
    end)
end)
