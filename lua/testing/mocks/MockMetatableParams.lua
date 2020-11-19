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

local ClassLogger = require("lua/logger/ClassLogger")

local cLogger = ClassLogger.new{className = "MockMetatableParams"}

local checkMap

-- Parameters to build a new MockMetatable object.
--
-- Fields:
-- * className: string. Name of the new class.
-- * fallbackGetter: function(object, any) -> boolean,any. Function called when `index` is not in `getters`.
-- * getters[any]: function(object) -> *. Map of getter methods, indexed by the key to read.
-- * setters[any]: function(object, value). Map of setter methods, indexed by the key to write.
--
local MockMetatableParams = {
    -- Checks if a MockMetatableParams object has correct values.
    --
    -- Args:
    -- * object: MockMetatableParams. Table to check.
    --
    -- Returns: The argument.
    --
    check = function(object)
        cLogger:assertFieldType(object, "className", "string")

        checkMap(object, "getters", "string", "function")
        checkMap(object, "setters", "string", "function")

        if object.fallbackGetter then
            cLogger:assert(type(object.fallbackGetter) == "function", "Invalid fallbackGetter (function expected).")
        end

        return object
    end,
}

-- Checks a map in an object.
--
-- Args:
-- * self: table. Object containing the map.
-- * mapName: any. Index of the map in `self`.
-- * keyType (optional): string. Expected type of the keys.
-- * valueType (optional): string. Expected type of the values.
--
checkMap = function(self, mapName, keyType, valueType)
    local map = self[mapName]
    if map then
        for key,value in pairs(map) do
            if keyType then
                if type(key) ~= keyType then
                    cLogger:error("Invalid key in " .. mapName .. " (" .. tostring(keyType) .. " expected): '" .. tostring(key) .. "'.")
                end
            end
            if valueType then
                if type(value) ~= valueType then
                    cLogger:error("Invalid value in " .. mapName .. " (" .. tostring(keyType) .. " expected) at key '" .. tostring(key) .. "'.")
                end
            end
        end
    end
end

return MockMetatableParams
