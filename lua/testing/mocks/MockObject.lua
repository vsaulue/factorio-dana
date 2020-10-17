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

local MockMetatable = require("lua/testing/mocks/MockMetatable")

local DataIndex
local getClassLogger
local Metatable

-- Class providing extensive read/write access control for mocking purposes.
--
-- Fields are not directly stored in the object's table. They are instead stored
-- in a "data" table (hidden at `DataIndex`). This enables interception of all read/write
-- operations via __index/__newindex.
--
-- The default __index & __newindex of this class errors when accessing an unknown key.
--
local MockObject = {
    -- Gets the ClassLogger object of the specified MockObject.
    --
    -- Args:
    -- * self: MockObject.
    --
    -- Returns: The ClassLogger for the type of `self`.
    --
    getClassLogger = function(self)
        return getmetatable(self).cLogger
    end,

    -- Gets the internal data table if the object is still valid.
    --
    -- Args:
    -- * self: MockObject.
    --
    -- Returns: table or nil. The data table if the object is valid, nil otherwise.
    --
    getDataIfValid = function(self)
        return rawget(self, DataIndex)
    end,

    -- Gets the internal data table, or error if the object is not valid.
    --
    -- Args:
    -- * self: AbstractGuiElement object.
    -- * index (optional): any. Index being accessed (for logging purposes only).
    --
    -- Returns: table. The data table of this object.
    --
    getData = function(self, index)
        local result = rawget(self, DataIndex)
        if not result then
            local msg
            if index then
                msg = "Attempt to access field '" .. tostring(index) .. "' of an invalid object."
            else
                msg = "Object is not valid."
            end
            getClassLogger(self):error(msg)
        end
        return result
    end,

    -- Invalidates a MockObject.
    --
    -- This deletes the internal data table.
    --
    -- Args:
    -- * self: MockObject.
    --
    invalidate = function(self)
        self[DataIndex] = nil
    end,

    -- Creates a new MockObject.
    --
    -- Args:
    -- * data (optional): table. Value to use as the internal data table.
    -- * metatable (optional): Metatable to set to the new object.
    --
    -- Returns: MockObject. The newly construct object.
    --
    make = function(data, metatable)
        local result = {
            [DataIndex] = data or {},
        }
        setmetatable(result, metatable or Metatable)
        return result
    end,

    -- Metatable of the MockObject class.
    Metatable = MockMetatable.new{
        className = "MockObject",

        __index = function(self, index)
            getClassLogger(self):error("Invalid read at '" .. tostring(index) .. "'.")
        end,

        __newindex = function(self, index)
            getClassLogger(self):error("Invalid write at '" .. tostring(index) .. "'.")
        end,
    },
}

-- "Secret" index in which the data table is stored.
DataIndex = {}

getClassLogger = MockObject.getClassLogger
Metatable = MockObject.Metatable

return MockObject
