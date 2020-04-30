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

local Logger = require("lua/logger/Logger")

-- Implementation of a FIFO data structure.
--
-- Stored in global: no.
--
-- RO properties:
-- * start: index of the oldest element of the queue.
-- * count: number of elements in the queue.
-- * data: array holding the values in the queue.
--
-- Methods:
-- * dequeue: removes and returns the oldest element of the queue.
-- * enqueue: adds a new element in the queue.
--
local Queue = {
    new = nil,
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the Queue class.
    Metatable = {
        __index = {
            -- Removes and returns the oldest element of this queue.
            --
            -- Args:
            -- * self: the Stack object.
            --
            -- Returns: the dequeued value.
            --
            dequeue = function(self)
                local result = self.data[self.start]
                if self.count > 0 then
                    self.data[self.start] = nil
                    self.count = self.count - 1
                    self.start = self.start + 1
                else
                    Logger.error("Calling dequeue on an empty queue.")
                end
                return result
            end,

            -- Adds a new element in the queue.
            --
            -- Args:
            -- * self: the Stack object.
            -- * newValue: value to add to the stack.
            --
            enqueue = function(self,newValue)
                self.data[self.start + self.count] = newValue
                self.count = self.count + 1
            end
        },
    },
}

function Queue.new()
    local result = {
        start = 1,
        count = 0,
        data = {},
    }
    setmetatable(result,Impl.Metatable)
    return result
end

return Queue
