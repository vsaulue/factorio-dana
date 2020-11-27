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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "MetaUtils"}

-- Utility library to manipulate metatables.
local MetaUtils = ErrorOnInvalidRead.new{
    -- Chains the __index fields of two Metatable to implement class inheritance.
    --
    -- Args:
    -- * baseMetatable: table. Metatable of the parent class.
    -- * derivedMetatable: table. Metatable of the child class.
    --
    derive = function(baseMetatable, derivedMetatable)
        local baseIndex = baseMetatable.__index
        local derivedIndex = derivedMetatable.__index
        cLogger:assert(derivedIndex, "derive() required the derived metatable to have an __index.")
        if baseIndex and derivedIndex then
            cLogger:assert(type(baseIndex) == "table", "derive() only works for table __index.")
            setmetatable(derivedIndex, {__index = baseIndex})
            -- Note: if derivedIndex is also a table, adding its elements directly into baseIndex
            -- could help with performances.
        end
        return derivedMetatable
    end,

    -- Restores the metatable of a field (if not nil).
    --
    -- Args:
    -- * container: table. Table containing the field to modify.
    -- * index: any. Index of the field to modify in `container`.
    -- * setter: function(any). Metatable setter to use.
    --
    safeSetField = function(container, index, setter)
        local value = rawget(container, index)
        if value then
            setter(value)
        end
    end,
}

return MetaUtils
