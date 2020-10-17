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

local MockReadOnlyWrapper = require("lua/testing/mocks/MockReadOnlyWrapper")
local MockObject = require("lua/testing/mocks/MockObject")

-- Library to generate some getters for MockMetatableParams.
--
local MockGetters = {
    -- Makes a getter which generates an error.
    --
    -- Useful to "hide" a public field of the parent metatable.
    --
    -- Args:
    -- * index: Index of this getter.
    --
    -- Returns: function(object). The generated getter.
    --
    hide = function(index)
        return function(self)
            MockObject.Metatable.__index(self, index)
        end
    end,

    -- Makes a getter for MockObject: forwards the value in the "data" field.
    --
    -- The getter generates an error if the object is not valid.
    --
    -- Args:
    -- * index: Index of this getter.
    --
    -- Returns: function(object) -> any. The generated getter.
    --
    validTrivial = function(index)
        return function(self)
            local data = MockObject.getDataIfValid(self)
            if data then
                return data[index]
            else
                MockObject.getClassLogger(self):error("Attempt to access field '" .. index .. "' of an invalid object.")
            end
        end
    end,

    -- Makes a getter for MockObject: wraps the value in the "data" field in a MockReadOnlyWrapper.
    --
    -- The getter generates an error if the object is not valid.
    --
    -- Args:
    -- * index: Index of this getter.
    --
    -- Returns: function(object) -> MockReadOnlyWrapper<table>. The generated getter.
    --
    validReadOnly = function(index)
        return function(self)
            local data = MockObject.getDataIfValid(self)
            if data then
                return MockReadOnlyWrapper.make(data[index])
            else
                MockObject.getClassLogger(self):error("Attempt to access field '" .. index .. "' of an invalid object.")
            end
        end
    end,
}

return MockGetters
