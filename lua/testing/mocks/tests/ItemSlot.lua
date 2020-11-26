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

local ItemSlot = require("lua/testing/mocks/ItemSlot")

describe("ItemSlot", function()
    local object
    before_each(function()
        object = ItemSlot.new()
    end)

    local setValidStack = function()
        object.name = "coal"
        object.count = 7
    end

    it(".new()", function()
        assert.is_nil(object.name)
    end)

    describe(":get('valid_for_read')", function()
        it("-- false", function()
            assert.is_false(object:get("valid_for_read"))
        end)

        it("-- true", function()
            setValidStack()
            assert.is_true(object:get("valid_for_read"))
        end)
    end)

    describe(":get('count')", function()
        it("-- valid", function()
            setValidStack()
            assert.are.equals(object:get("count"), 7)
        end)

        it("-- invalid", function()
            assert.error(function()
                object:get("count")
            end)
        end)
    end)

    describe(":get('name')", function()
        it("-- valid", function()
            setValidStack()
            assert.are.equals(object:get("name"), "coal")
        end)

        it("-- invalid", function()
            assert.error(function()
                object:get("name")
            end)
        end)
    end)

    describe(":set('count')", function()
        it("-- valid, non-zero", function()
            setValidStack()
            object:set("count", 2)
            assert.are.equals(object.count, 2)
        end)

        it("-- valid, 0", function()
            setValidStack()
            object:set("count", 0)
            assert.is_nil(object.name)
            assert.is_nil(object.count)
        end)

        it("-- invalid, negative", function()
            setValidStack()
            assert.error(function()
                object:set("count", -1)
            end)
        end)

        it("-- invalid (empty)", function()
            assert.error(function()
                object:set("count", 5)
            end)
        end)
    end)

    describe(":set_stack()", function()
        it("-- non-empty", function()
            object:setStack{
                name = "iron-ore",
                count = 13,
                foobar = true,
            }
            assert.are.same(object, {
                name = "iron-ore",
                count = 13,
            })
        end)

        it("-- empty", function()
            setValidStack()
            object:setStack()
            assert.are.same(object, {})
        end)
    end)
end)