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

local Stack = require("lua/containers/Stack")

local setSampleStack

describe("Stack", function()
    local stack

    before_each(function()
        stack = Stack.new()
    end)

    after_each(function()
        stack = nil
    end)

    it("constructor", function()
        assert.are.equals(stack.topIndex, 0)
    end)

    it("setmetatable", function()
        local testStack = {
            topIndex = 0,
        }
        Stack.setmetatable(testStack)
        assert.are.equals(testStack.push, stack.push)
    end)

    describe(":pop()", function()
        it("-- valid", function()
            setSampleStack(stack)
            local value = stack:pop()
            assert.are.equals(value, 49)
            assert.are.equals(stack.topIndex, 6)
        end)

        it("-- empty stack (error)", function()
            assert.error(function()
                stack:pop()
            end)
        end)
    end)

    describe(":pop2()", function()
        it("-- valid", function()
            setSampleStack(stack)
            local value1,value2 = stack:pop2()
            assert.are.equals(value1, 36)
            assert.are.equals(value2, 49)
            assert.are.equals(stack.topIndex, 5)
        end)

        it("-- less than 2 items on the stack (error)", function()
            stack[1] = 1
            stack.topIndex = 1
            assert.error(function()
                stack:pop2()
            end)
        end)
    end)

    it(":push()", function()
        setSampleStack(stack)
        stack:push(64)

        local topIndex = 8
        assert.are.equals(stack.topIndex, topIndex)
        for i=1,topIndex do
            assert.are.equals(stack[i], i*i)
        end
    end)

    it(":push2()", function()
        setSampleStack(stack)
        stack:push2(64,81)

        local topIndex = 9
        assert.are.equals(stack.topIndex, topIndex)
        for i=1,topIndex do
            assert.are.equals(stack[i], i*i)
        end
    end)
end)

-- Fills a Stack object with hardcoded values.
--
-- Args:
-- * stack: Stack to fill.
--
setSampleStack = function(stack)
    local topIndex = 7
    for i=1,topIndex do
        stack[i] = i*i
    end
    stack.topIndex = topIndex
end
