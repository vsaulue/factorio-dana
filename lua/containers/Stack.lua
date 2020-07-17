-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Logger = require("lua/logger/Logger")

local Metatable

-- Container class with stack semantics.
--
-- This class does not support nil values.
--
-- RO fields:
-- * topIndex: index of the item in the stack (also the number of items in the stack).
-- * [N]: The N-th value from the bottom of the stack.
--
-- Methods: see Metatable.__index
--
local Stack = ErrorOnInvalidRead.new{
    -- Creates a new empty stack.
    --
    -- Returns: A new empty stack.
    --
    new = function()
        local result = {
            topIndex = 0,
        }
        setmetatable(result, Metatable)
        return result
    end,

    -- Assigns Stack's metatable to the argument.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the Stack class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Inserts a new element on top of the stack.
        --
        -- Args:
        -- * self: Stack object.
        -- * value: Object to add on top of the stack.
        --
        push = function(self, value)
            self.topIndex = self.topIndex + 1
            self[self.topIndex] = value
        end,

        -- Inserts two elements on top of the stack.
        --
        -- Args:
        -- * self: Stack object.
        -- * value1: First object to add.
        -- * value2: Second object to add.
        --
        push2 = function(self, value1, value2)
            local topIndex = self.topIndex + 1
            self[topIndex] = value1
            topIndex = topIndex + 1
            self[topIndex] = value2
            self.topIndex = topIndex
        end,

        -- Removes & returns the object on top of the stack.
        --
        -- Args:
        -- * self: Stack object.
        --
        -- Returns: the object removed from the top of the stack.
        --
        pop = function(self)
            local topIndex = self.topIndex
            assert(self.topIndex > 0, "Stack: pop called on an empty stack.")
            local result = self[topIndex]
            self[topIndex] = nil
            self.topIndex = topIndex - 1
            return result
        end,

        -- Removes & returns the 2 objects on top of the stack.
        --
        -- Args:
        -- * self: Stack object.
        --
        -- Returns:
        -- * The (previousTop - 1) value.
        -- * The (previousTop) value.
        --
        pop2 = function(self)
            local topIndex = self.topIndex
            assert(topIndex >= 2, "Stack: pop2 called on a stack with less than 2 elements")

            local result2 = self[topIndex]
            self[topIndex] = nil
            topIndex = topIndex - 1
            local result1 = self[topIndex]
            self[topIndex] = nil

            self.topIndex = topIndex - 1
            return result1,result2
        end,
    }
}

return Stack
