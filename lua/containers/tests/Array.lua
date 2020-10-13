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

local Array = require("lua/containers/Array")
local Iterator = require("lua/containers/utils/Iterator")
local OrderedSet = require("lua/containers/OrderedSet")

local checkArray
local runPairTest

describe("Array", function()
    describe(".new()", function()
        it("-- nil arg", function()
            local array = Array.new()
            assert.are.equals(array.count, 0)
        end)

        it("-- from Lua array", function()
            local cArgs = {9,7,5,3,1}
            local array = Array.new(cArgs)
            assert.are.equals(array, cArgs)
            assert.are.equals(array.count, 5)
        end)
    end)

    describe(".setmetatable()", function()
        it("-- Restore value's metatables", function()
            local array = {
                [1] = {},
                [2] = {},
                [3] = {},
                count = 3,
            }
            local metatable = {
                __index = {
                    foo = "baR",
                },
            }
            Array.setmetatable(array, function(value)
                setmetatable(value, metatable)
            end)

            for i=1,array.count do
                assert.are.equals(array[i].foo, metatable.__index.foo)
            end
            assert.is_not_nil(array.pushBack)
        end)

        it("-- No metatable on values", function()
            local array = {"a","b", count = 2}
            Array.setmetatable(array)
            assert.is_not_nil(array.pushBack)
        end)
    end)

    it(":close", function()
        local count = 3
        local makeCloseable = function()
            return {
                close = function(self)
                    count = count - 1
                    self.close = nil
                end,
            }
        end
        local array = Array.new()
        for i=1,count do
            array:pushBack(makeCloseable())
        end
        array:close()

        assert.are.equals(count, 0)
    end)

    it(":loadFromOrderedSet()", function()
        local orderedSet = OrderedSet.new()
        for i=4,1,-1 do
            orderedSet:pushBack(i)
        end

        local array = Array.new()
        array:loadFromOrderedSet(orderedSet)

        checkArray(array, {4,3,2,1})
    end)

    it(":pushBack()", function()
        local array = Array.new{4,3,2}
        array:pushBack(1)

        checkArray(array, {4,3,2,1})
    end)

    it(":pushBackIteratorAll()", function()
        local array = Array.new{5,4,3}
        local array2 = Array.new{3,2,1}
        local it = Iterator.new(array2)
        it:next()
        it:next()
        array:pushBackIteratorAll(it)

        checkArray(array, {5,4,3,2,1})
    end)

    it(":pushBackIteratorOnce()", function()
        local array = Array.new{5,4,3}
        local array2 = Array.new{3,2,1}
        local it = Iterator.new(array2)
        it:next()
        it:next()
        array:pushBackIteratorOnce(it)

        checkArray(array, {5,4,3,2})
    end)

    it(":sort()", function()
        local array = Array.new{"b","c","a","e","d"}
        local weights = {
            a = 1,
            b = 2,
            c = 3,
            d = 4,
            e = 5,
        }
        array:sort(weights)

        checkArray(array, {"a","b","c","d","e"})
    end)

    describe("__eq", function()
        it("-- true", function()
            local array1 = Array.new{4,8,12}
            local array2 = Array.new{4,8,12}
            assert.are.equals(array1, array2)
            assert.are.equals(array2, array1)
        end)

        it("-- false (different count)", function()
            local array1 = Array.new{4,8,12}
            local array2 = Array.new{4,8,12,13}
            assert.are_not.equals(array1, array2)
            assert.are_not.equals(array2, array1)
        end)

        it("-- false (different value)", function()
            local array1 = Array.new{1,1,3}
            local array2 = Array.new{1,2,3}
            assert.are_not.equals(array1, array2)
            assert.are_not.equals(array2, array1)
        end)
    end)

    it("__ipairs", function()
        runPairTest(ipairs)
    end)

    it("__len", function()
        local array = Array.new()
        array.count = 66
        assert.are.equals(#array, 66)
    end)

    it("__pairs", function()
        runPairTest(pairs)
    end)
end)

-- Checks the content of an Array object.
--
-- Args:
-- * array: Array object to check.
-- * expected: Lua array containing the expected values.
--
checkArray = function(array, expected)
    local count = #expected
    for i=1,count do
        assert.are.equals(array[i], expected[i])
    end

    assert.are.equals(array.count, count)
end

-- Tests one of the pair metamethod of Array.
--
-- Args:
-- * pairFunction: function to test (either pairs or ipairs).
--
runPairTest = function(pairFunction)
    local array = Array.new{3,6,9}
    local f,c,k = pairFunction(array)
    local v
    for i=1,3 do
        k,v = f(c,k)
        assert.are.equals(k, i)
        assert.are.equals(v, 3*i)
    end
    k,v = f(c,k)
    assert.is_nil(k)
end
