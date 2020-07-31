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
local LayerLinkIndex = require("lua/layouts/layer/LayerLinkIndex")

local Metatable

-- Factory for LayerLinkIndex objects.
--
-- This implementation does memoization, and ensure the same LayerLinkIndex is always returned for
-- the same field values. This enables fast comparison and map lookup.
--
-- RO fields:
-- * cache[isForward,isFromVertexToEdge,vertexId]: 3-levels deep table caching already generated LayerLinkIndex objects.
--
-- Methods:
-- * get: Gets (or create) the LayerLinkIndex object associated with the arguments.
--
local LayerLinkIndexFactory = ErrorOnInvalidRead.new{
    -- Creates a new LayerLinkIndexFactory.
    --
    -- Returns: A new LayerLinkIndexFactory object.
    --
    new = function()
        local result = {
            cache = ErrorOnInvalidRead.new{
                [true] = ErrorOnInvalidRead.new{
                    [true] = {},
                    [false] = {},
                },
                [false] = ErrorOnInvalidRead.new{
                    [true] = {},
                    [false] = {},
                },
            },
        }
        setmetatable(result, Metatable)
        return result
    end,
}

-- Metatable of the LayerLinkIndexFactory class (private scope).
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets (or create) the LayerLinkIndex object associated with the arguments.
        --
        -- If this factory already returned an object for the given vertexIndex/isforward
        -- value, it is guaranteed to return the same object on future calls of this method.
        --
        -- Args:
        -- * self: LayerLinkIndexFactory object.
        -- * vertexIndex: vertexIndex value of the LayerLinkIndex.
        -- * isForward: isForward value of the LayerLinkIndex.
        -- * isFromVertexToEdge: isFromVertexToEdge value of the LayerLinkIndex.
        --
        -- Returns: A ChannelObject instance with the specified vertexIndex/isForward values.
        get = function(self, vertexIndex, isForward, isFromVertexToEdge)
            local result = self.cache[isForward][isFromVertexToEdge][vertexIndex]
            if not result then
                result = LayerLinkIndex.new{
                    isForward = isForward,
                    isFromVertexToEdge = isFromVertexToEdge,
                    vertexIndex = vertexIndex,
                }
                self.cache[isForward][isFromVertexToEdge][vertexIndex] = result
            end
            return result
        end,
    },
}

return LayerLinkIndexFactory
