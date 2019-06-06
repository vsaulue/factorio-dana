-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local Logger = require("lua/Logger")

-- Container class with stack semantics.
--
-- Stored in global: no.
--
-- Methods:
-- * push: adds a new value on top of the stack.
-- * pop: removes & return the value on top of the stack.
--
-- RO properties:
-- * topIndex: index of the item in the stack (also the number of items in the stack).
--
local Stack = {
    new = nil, -- implemented later
}

-- Container
local Impl = {
    Metatable = {
        __index = {
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

            -- Removes & returns the object on top of the stack.
            --
            -- Args:
            -- * self: Stack object.
            --
            -- Returns: the object removed from the top of the stack.
            --
            pop = function(self)
                local result = self[self.topIndex]
                if (self.topIndex > 0) then
                    self[self.topIndex] = nil
                    self.topIndex = self.topIndex - 1
                else
                    Logger.error("Stack: pop called on an empty stack.")
                end
                return result
            end,
        }
    }
}

-- Creates a new empty stack.
--
-- Returns: A new empty stack.
--
function Stack.new()
    local result = {
        topIndex = 0,
    }
    setmetatable(result, Impl.Metatable)
    return result
end

return Stack