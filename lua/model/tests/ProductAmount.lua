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
    it(".copy()", function()
        local object = ProductAmount.copy{
            amountMax = 123,
            amountMin = 101,
            probability = 0.5,
        }
        assert.are.same(object, {
            amountMax = 123,
            amountMin = 101,
            probability = 0.5,
        })
    end)

    describe(".equals()", function()
        local o1
        local o2
        before_each(function()
            o1 = {
                amountMax = 21,
                amountMin = 12,
                probability = 0.125,
            }
            o2 = {
                amountMax = 21,
                amountMin = 12,
                probability = 0.125,
            }
        end)

        it("-- true", function()
            assert.is_true(ProductAmount.equals(o1, o2))
        end)

        it("-- false, amountMax", function()
            o1.amountMax = 22
            assert.is_false(ProductAmount.equals(o1, o2))
        end)

        it("-- false, amountMax", function()
            o1.amountMin = 11
            assert.is_false(ProductAmount.equals(o1, o2))
        end)

        it("-- false, amountMax", function()
            o1.probability = 0.25
            assert.is_false(ProductAmount.equals(o1, o2))
        end)
    end)

    it(".makeConstant()", function()
        local object = ProductAmount.makeConstant(654)
        assert.are.same(object, {
            amountMax = 654,
            amountMin = 654,
            probability = 1,
        })
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