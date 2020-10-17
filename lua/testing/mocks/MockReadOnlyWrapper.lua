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
local MockObject = require("lua/testing/mocks/MockObject")

local getData = MockObject.getDataIfValid

local cLogger
local Metatable

-- Class to make write-protected references to tables.
--
-- The wrapper only prevent overriding any key in the table, but doesn't prevent modification of a value:
-- * wrapper[someKey] = someValue   -- error
-- * wrapper[someKey].someOtherKey = someValue    -- valid.
--
-- RO Fields:
-- * all RO Fields of the wrapped object.
--
local MockReadOnlyWrapper = {
    make = function(data)
        return MockObject.make(data, Metatable)
    end,
}

-- Metatable of the MockReadOnlyWrapper class.
Metatable = MockMetatable.new{
    className = "MockReadOnlyWrapper",

    __index = function(self, index)
        return getData(self)[index]
    end,

    __newindex = function(self, index)
        cLogger:error("Object is read-only.")
    end,

    __pairs = function(self)
        return pairs(getData(self))
    end,

    __ipairs = function(self)
        return ipairs(getData(self))
    end,
}

cLogger = Metatable.cLogger

return MockReadOnlyWrapper
