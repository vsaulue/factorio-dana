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

local deepCopyImpl

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

    -- Makes a getter which generates a deep copy of the field of the same name.
    --
    -- Args:
    -- * index: Index of this getter.
    --
    -- Returns: function(object). The generated getter.
    validDeepCopy = function(index)
        return function(self)
            local data = MockObject.getData(self, index)
            return deepCopyImpl(data[index], {})
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
            local data = MockObject.getData(self)
            return data[index]
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
            local data = MockObject.getData(self)
            return MockReadOnlyWrapper.make(data[index])
        end
    end,
}

-- Makes a deep copy of an object.
--
-- Args:
-- * object: any. Object to copy.
-- * cache: Map[table] -> table. Map of generated tables, indexed by their source tables.
--
-- Returns: The generated object.
--
deepCopyImpl = function(object, cache)
    local result = object
    if type(object) == "table" then
        result = cache[object]
        if not result then
            result = {}
            cache[object] = result
            local k,v = next(object)
            while k ~= nil do
                result[deepCopyImpl(k,cache)] = deepCopyImpl(v,cache)
                k,v = next(object, k)
            end
        end
    end
    return result
end

return MockGetters
