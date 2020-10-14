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

local Metatable

-- Utility to make tables throw errors on invalid reads.
--
local ErrorOnInvalidRead = {
    -- Creates a new ErrorOnInvalidRead table.
    --
    -- Args:
    -- * Table to turn into a ErrorOnInvalidRead object, or nil to create a new table.
    --
    -- Returns: The new ErrorOnInvalidRead table.
    --
    new = function(object)
        local result = object or {}
        setmetatable(result, Metatable)
        return result
    end,

    -- Assigns ErrorOnInvalidRead's metatable to the argument.
    --
    -- Args:
    -- * object: table. Object to restore.
    -- * keySetter (optional): function. Function to restore the metatable of keys.
    -- * valueSetter (optional): function. Function to restore the metatable of values.
    --
    setmetatable = function(object, keySetter, valueSetter)
        setmetatable(object, Metatable)
        if keySetter or valueSetter then
            for k,v in pairs(object) do
                if keySetter then
                    keySetter(k)
                end
                if valueSetter then
                    valueSetter(v)
                end
            end
        end
    end,
}

-- Metatable of the ErrorOnInvalidRead class.
Metatable = {
    __index = function(self,field)
        Logger.error("Invalid access at index: " .. tostring(field))
    end,
}

setmetatable(ErrorOnInvalidRead, Metatable)
return ErrorOnInvalidRead
