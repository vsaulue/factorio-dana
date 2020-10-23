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
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ProductAmount", function()
    it(".makeConstant()", function()
        local object = ProductAmount.makeConstant(654)
        assert.are.same(object, {
            amountMax = 654,
            amountMin = 654,
            probability = 1,
        })
    end)

    describe(".makeFromRawProduct", function()
        it("-- amount_max & amount_min", function()
            local object = ProductAmount.makeFromRawProduct{
                amount_max = 999,
                amount_min = 789,
                probability = 0.125,
            }
            assert.are.same(object, {
                amountMax = 999,
                amountMin = 789,
                probability = 0.125,
            })
        end)

        it("-- amount", function()
            local object = ProductAmount.makeFromRawProduct{
                amount = 12,
            }
            assert.are.same(object, {
                amountMax = 12,
                amountMin = 12,
                probability = 1,
            })
        end)
    end)

    it(".setmetatable()", function()
        local object = ProductAmount.new{
            amountMax = 4,
            amountMin = 2,
            probability = 1,
        }
        SaveLoadTester.run{
            objects = object,
            metatableSetter = ProductAmount.setmetatable,
        }
    end)

    describe(":getAvg()", function()
        local object = ProductAmount.new{
            amountMax = 123,
            amountMin = 77,
            probability = 0.75,
        }
        assert.are.equals(object:getAvg(), 75)
    end)
end)