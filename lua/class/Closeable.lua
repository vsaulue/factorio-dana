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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

-- Interface implemented by all objects holding system resources.
--
-- In Factorio, "system" resources would be entities, rendering objects, GUI elements...
--
-- This interface simply defines a close() method, which releases all the resources owned
-- by this Closeable object.
--
local Closeable = ErrorOnInvalidRead.new{
    -- Call close on all keys in a map.
    --
    -- Args:
    -- * map: Map<Closeable,*>. Map to close.
    --
    closeMapKeys = function(map)
        for key in pairs(map) do
            key:close()
        end
    end,

    -- Call close on all values in a map.
    --
    -- Args:
    -- * map: Map<*,Closeable>. Map to close.
    --
    closeMapValues = function(map)
        for _,value in pairs(map) do
            value:close()
        end
    end,

    -- Closes the argument if not nil.
    --
    -- Args:
    -- * object: Closeable or nil. Object to close.
    --
    safeClose = function(object)
        if object then
            object:close()
        end
    end,

    -- Closes a specific field of a table, and removes it.
    --
    -- Args:
    -- * container: Table containing the Closeable object.
    -- * index: Index of the Closeable object in `container` to close.
    --
    safeCloseField = function(container, index, erase)
        local value = rawget(container, index)
        if value then
            value:close()
            container[index] = nil
        end
    end,
}

--[[
Metatable = {
    __index = {
        -- Releases all system resources held by this object.
        --
        -- Args:
        -- * self: Closeable object.
        --
        close = function(self) end,
    }
}
--]]

return Closeable
