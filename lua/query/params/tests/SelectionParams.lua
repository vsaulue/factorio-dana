-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local SaveLoadTester = require("lua/testing/SaveLoadTester")
local SelectionParams = require("lua/query/params/SelectionParams")

describe("SelectionParams", function()
    describe(".new()", function()
        it("-- with arg", function()
            local object = {
                enableFuels = "a",
                enableRecipes = false,
            }
            local result = SelectionParams.new(object)
            assert.are.equals(object, result)
            assert.is_not_nil(object.newCopy)
            assert.are.same(object, {
                enableBoilers = false,
                enableFuels = true,
                enableRecipes = false,
                enableResearches = false,
            })
        end)

        it("-- no arg", function()
            local object = SelectionParams.new()
            assert.is_not_nil(object.newCopy)
            assert.are.same(object, {
                enableBoilers = true,
                enableFuels = true,
                enableRecipes = true,
                enableResearches = false,
            })
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = SelectionParams.new{
                enableBoilers = true,
                enableFuels = false,
                enableResearches = true,
            }
        end)

        it(":newCopy()", function()
            local copy = object:newCopy()

            assert.are.same(copy, {
                enableBoilers = true,
                enableFuels = false,
                enableRecipes = false,
                enableResearches = true,
            })
            assert.are.equals(object.newCopy, copy.newCopy)
        end)

        it(".setmetatable()", function()
            SaveLoadTester.run{
                objects = object,
                metatableSetter = SelectionParams.setmetatable,
            }
        end)
    end)
end)