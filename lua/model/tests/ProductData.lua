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

local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ProductData", function()
    it(".make()", function()
        local object = ProductData.make(ProductAmount.new{
            amountMin = 5,
            amountMax = 8,
            probability = 0.5,
        })
        assert.are.same(object, {
            count = 1,
            [1] = {
                amountMin = 5,
                amountMax = 8,
                probability = 0.5,
            },
        })
    end)

    describe("", function()
        local object
        before_each(function()
            object = ProductData.make(ProductAmount.makeConstant(42))
        end)

        it(":addAmount()", function()
            object:addAmount(ProductAmount.makeConstant(24))
            assert.are.same(object, {
                count = 2,
                [1] = ProductAmount.makeConstant(42),
                [2] = ProductAmount.makeConstant(24),
            })
        end)

        it(":getAvg()", function()
            object:addAmount(ProductAmount.new{
                amountMax = 16,
                amountMin = 8,
                probability = 0.25
            })
            assert.are.equals(object:getAvg(), 45)
        end)

        it(".setmetatable()", function()
            SaveLoadTester.run{
                objects = object,
                metatableSetter = ProductData.setmetatable,
            }
        end)
    end)
end)