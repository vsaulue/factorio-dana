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

local Logger = require("lua/logger/Logger")

-- Class implementing a generic iterator for key/value or key-only containers.
--
-- The main feature of this class is enabling the copy of iterators. If it is not needed,
-- iterating with the good old `for k,v in pairs(t) do ... end` will be faster and more readable.
--
-- Typical usage:
-- ```
-- local aTable = {hello= "world", foo="bar"}
-- local it = Iterator.new(aTable)
-- while it:next() do
--     print("key: " .. it.key .. ", value: " it.value)
-- end
-- ```
--
-- RO properties:
-- * constantArg: Second value returned from `pairs(...)`.
-- * key: Current index from the iterated container.
-- * value: Current value from the iterated container.
--
-- Methods:
-- * copy: Overwrites this iterator, by copying another one.
-- * next: Advance to the next key/value.
--
local Iterator = {
    new = nil, -- implemented later
}

local Impl = {
    -- Next method of non-initialized iterator (terminates the program).
    --
    InvalidNextFunction = function()
        Logger.error("Iterator: attempt to iterate with an unititialized iterator.")
    end,

    -- Metatable of the Iterator class.
    Metatable = {
        __index = {
            -- Overwrites the current iterator, by copying another one.
            --
            -- Args:
            -- * self: Iterator object to write.
            -- * sourceIterator: Iterator to copy.
            --
            copy = function(self, sourceIterator)
                self.constantArg = sourceIterator.constantArg
                self.next = sourceIterator.next
                self.key = sourceIterator.key
                self.value = sourceIterator.value
            end,
        },
    },
}

-- Creates a new iterator.
--
-- Args:
-- * container: The container on which to iterate. Can be nil: the iterator must be initialized later with its methods.
--
-- Returns: the new iterator.
--
function Iterator.new(container)
    local f,c,i = Impl.InvalidNextFunction
    if container then
        f,c,i = pairs(container)
    end
    local result = {
        constantArg = c,
        key = i,
        next = function(self)
            local key,value = f(self.constantArg, self.key)
            self.key = key
            self.value = value
            return key ~= nil
        end,
    }
    setmetatable(result, Impl.Metatable)
    return result
end

return Iterator
