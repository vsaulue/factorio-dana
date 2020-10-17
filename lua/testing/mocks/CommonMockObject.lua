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

local Metatable

-- Abstract class for object implementing the common fields.
--
-- See https://lua-api.factorio.com/latest/Common.html
--
-- Inherits from MockObject.
--
-- Implemented fields & methods:
-- * valid
--
local CommonMockObject = {
    -- Creates a new CommonMockObject instance.
    --
    -- Args:
    -- * data (optional): table. Internal data to use as MockObject.
    -- * metatable (optional): table. Metatable to set.
    --
    -- Returns: CommonMockObject. The new object.
    make = function(data, metatable)
        return MockObject.make(data, metatable or Metatable)
    end,

    -- Metatable of the CommonMockObject class.
    Metatable = MockObject.Metatable:makeSubclass{
        className = "CommonMockObject",
        getters = {
            valid = function(self)
                return MockObject.getDataIfValid(self) ~= nil
            end,
        },
    },
}

Metatable = CommonMockObject.Metatable

return CommonMockObject
