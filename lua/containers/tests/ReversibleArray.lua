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

local ReversibleArray = require("lua/containers/ReversibleArray")

local checkKeyValue
local checkRevArray
local setSampleRevArray
local testPairFunction

describe("ReversibleArray", function()
    local revArray

    before_each(function()
        revArray = ReversibleArray.new()
    end)

    after_each(function()
        revArray = nil
    end)

    it("constructor", function()
        assert.are.equals(revArray.count, 0)
        assert.is_not_nil(revArray.reverse)
    end)

    it("setmetatable", function()
        local test = {
            count = 1,
            reverse = {
                Hello = 1,
            },
            [1] = "Hello",
        }

        ReversibleArray.setmetatable(test)

        assert.is_not_nil(getmetatable(test))
        assert.is_not_nil(getmetatable(test.reverse))
    end)

    it("ipairs()", function()
        testPairFunction(revArray, ipairs)
    end)

    it("pairs()", function()
        testPairFunction(revArray, pairs)
    end)

    describe(":getLowHighValues", function()
        it("(low,high)", function()
            setSampleRevArray(revArray)

            local low,high = revArray:getLowHighValues("v4", "v6")
            assert.are.equals(low, "v4")
            assert.are.equals(high, "v6")
            checkRevArray(revArray)
        end)

        it("(high,low)", function()
            setSampleRevArray(revArray)

            local low,high = revArray:getLowHighValues("v7", "v2")
            assert.are.equals(low, "v2")
            assert.are.equals(high, "v7")
            checkRevArray(revArray)
        end)
    end)

    describe(":popBack", function()
        it("() -- empty array", function()
            assert.error(function()
                revArray:popBack()
            end)
        end)

        it("() -- valid", function()
            setSampleRevArray(revArray)

            local val = revArray:popBack()
            assert.are.equals(val, "v10")
            assert.are.equals(revArray.count, 9)
            assert.is_nil(rawget(revArray, 10))
            assert.is_nil(rawget(revArray.reverse, "v10"))
            checkRevArray(revArray)
        end)
    end)

    describe(":pushBack()", function()
        it("-- already present", function()
            setSampleRevArray(revArray)

            assert.error(function()
                revArray:pushBack("v4")
            end)
        end)

        it("-- invalid: nil", function()
            setSampleRevArray(revArray)

            assert.error(function()
                revArray:pushBack(nil)
            end)
        end)

        it("-- valid", function()
            setSampleRevArray(revArray)
            local TestVal = "-3"

            revArray:pushBack(TestVal)
            checkKeyValue(revArray, 11, TestVal)
            assert.are.equals(revArray.count, 11)
            checkRevArray(revArray)
        end)
    end)

    describe(":pushBackIfNotPresent()", function()
        it("-- duplicate", function()
            setSampleRevArray(revArray)

            revArray:pushBackIfNotPresent("v2")
            for i=1,10 do
                assert.are.equals(revArray[i], "v"..i)
            end
            assert.are.equals(revArray.count, 10)
            checkRevArray(revArray)
        end)

        it("-- new value", function()
            setSampleRevArray(revArray)
            local TestVal = "The factory shall grow !"

            revArray:pushBackIfNotPresent(TestVal)
            checkKeyValue(revArray, 11, TestVal)
            assert.are.equals(revArray.count, 11)
            checkRevArray(revArray)
        end)
    end)

    it(":removeValue()", function()
        setSampleRevArray(revArray)
        local TestVal = "v4"

        revArray:removeValue(TestVal)
        assert.is_nil(rawget(revArray.reverse, TestVal))
        assert.are.equals(revArray.count, 9)
        checkRevArray(revArray)
    end)

    it(":sort()", function()
        setSampleRevArray(revArray)

        -- v1 = 1, v2 = -2, v3 = 3, v4 = -4, ...
        local weights = {}
        local sign = 1
        for i=1,10 do
            weights["v"..i] = sign * i
            sign = - sign
        end

        revArray:sort(weights)
        for i=1,5 do
            checkKeyValue(revArray, i, "v" .. (12-2*i))
        end
        for i=1,5 do
            checkKeyValue(revArray, i+5, "v" .. (2*i-1))
        end
        checkRevArray(revArray)
    end)
end)

-- Checks that a ReversibleArray is in a consistent state.
--
-- Args:
-- * revArray: ReversibleArray object to check.
--
checkRevArray = function(revArray)
    local reverseCount = 0
    for value,index in pairs(revArray.reverse) do
        assert.are.equals(type(index), "number")
        assert.are.equals(revArray[index], value)
        assert.is_true(index <= revArray.count)
        reverseCount = reverseCount + 1
    end
    assert.are.equals(reverseCount, revArray.count)
end

-- Checks that an index/value pair is correctly set in a ReversibleArray.
--
-- Args:
-- * revArray: ReversibleArray object to test.
-- * index: Expected index of the pair.
-- * value: Expected value of the pair.
--
checkKeyValue = function(revArray, index, value)
    assert.is_true(index <= revArray.count)
    assert.are.equals(revArray[index], value)
    assert.are.equals(revArray.reverse[value], index)
end

-- Fills a ReversibleArray object with hardcoded values.
--
-- Args:
-- * revArray: ReversibleArray to fill.
--
setSampleRevArray = function(revArray)
    revArray.count = 10
    for i=1,revArray.count do
        local value = "v" .. i
        revArray[i] = value
        revArray.reverse[value] = i
    end
end

-- Tests the pairs/ipairs function on a ReversibleArray.
--
-- Args:
-- * revArray: ReversibleArray to test.
-- * pairFunction: Either `pairs` or `ipairs`.
--
testPairFunction = function(revArray, pairFunction)
    setSampleRevArray(revArray)

    local expectedIndex = 0
    for index,value in pairFunction(revArray) do
        expectedIndex = expectedIndex + 1
        assert.are.equals(index, expectedIndex)
        checkKeyValue(revArray, index, value)
    end
    assert.are.equals(revArray.count, expectedIndex)
end
