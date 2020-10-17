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

describe("IntermediatesDatabase", function()
    local gameScript = LuaGameScript.make{
        fluid = {
            water = {
                type = "fluid",
                name = "water",
            },
        },
        item = {
            wood = {
                type = "item",
                name = "wood",
            },
        },
    }

    it(".new()", function()
        local database = IntermediatesDatabase.new()
        assert.is_not_nil(database.fluid)
        assert.is_not_nil(database.item)
        assert.is_not_nil(database.rebuild)
    end)

    it(":rebuild()", function()
        local database = IntermediatesDatabase.new()
        database:rebuild(gameScript)
        assert.are.equals(database.item.wood.rawPrototype, gameScript.item_prototypes.wood)
        assert.are.equals(database.fluid.water.rawPrototype, gameScript.fluid_prototypes.water)
    end)

    describe("", function()
        local database
        before_each(function()
            database = IntermediatesDatabase.new()
            database:rebuild(gameScript)
        end)

        it(".setmetatable()", function()
            SaveLoadTester.run{
                objects = database,
                metatableSetter = IntermediatesDatabase.setmetatable,
            }
        end)

        it(":getIngredientOrProduct()", function()
            local intermediate = database:getIngredientOrProduct{
                type = "item",
                name = "wood",
            }
            assert.are.equals(database.item.wood, intermediate)
        end)
    end)
end)
