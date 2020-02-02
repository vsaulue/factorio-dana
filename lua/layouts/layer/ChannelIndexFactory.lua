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

-- Factory for ChannelIndex objects.
--
-- A ChannelIndex object is a 2 field table:
-- * isForward: true if the link is going from lower to higher index layer, false otherwise.
-- * vertexIndex: Unique identifier of a vertex in an hypergraph.
--
-- This implementation does memoization, and ensure the same ChannelIndex is always returned for
-- the same vertexIndex/isForward couple. This enables fast comparison and map lookup.
--
-- RO fields:
-- * cache[isForward,vertexId]: 2-levels deep table caching already generated ChannelIndex objects.
--
-- Methods:
-- * get: Gets (or create) the ChannelIndex object associated with the arguments.
--
local ChannelIndexFactory = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

-- Metatable of the ChannelIndexFactory class (private scope).
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets (or create) the ChannelIndex object associated with the arguments.
        --
        -- If this factory already returned an object for the given vertexIndex/isforward
        -- value, it is guaranteed to return the same object on future calls of this method.
        --
        -- Args:
        -- * self: ChannelIndexFactory object.
        -- * vertexIndex: vertexIndex value of the channel index.
        -- * isForward: isForward value of the channel index.
        --
        -- Returns: A ChannelObject instance with the specified vertexIndex/isForward values.
        get = function(self, vertexIndex, isForward)
            local result = self.cache[isForward][vertexIndex]
            if not result then
                result = ErrorOnInvalidRead.new{
                    isForward = isForward,
                    vertexIndex = vertexIndex,
                }
                self.cache[isForward][vertexIndex] = result
            end
            return result
        end,
    },
}

-- Creates a new ChannelIndexFactory.
--
-- Returns: A new ChannelIndexFactory object.
--
function ChannelIndexFactory.new()
    local result = {
        cache = ErrorOnInvalidRead.new{
            [true] = {},
            [false] = {},
        },
    }
    setmetatable(result, Metatable)
    return result
end

return ChannelIndexFactory
