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

local cLogger = ClassLogger.new{className = "FlyweightFactory"}

local Metatable

-- Factory to implement the Flyweight pattern (= reuse existing instances of objects when possible).
--
-- Template class: FlyWeightFactory<BuiltType>
-- * BuiltType: type of the interned values of this factory.
--
-- This object enables to use the Flyweight pattern, or "hash" consing (though the hash part remains to be
-- implemented). Main goals:
-- * replace deep comparison with simple reference comparison (== operator without __eq metamethod).
-- * enable indexing of tables with complex objects.
-- * saving memory for read-only data.
--
-- Note: This class would greatly benefit from hashing at some point.
--
-- RO Fields:
-- count: int.
-- [int]: BuiltType.
-- + functions (see Metatable).
--
local FlyweightFactory = ErrorOnInvalidRead.new{
    -- Creates a new FlyweightFactory object.
    --
    -- Args:
    -- * object: table. Required fields:
    --
    -- Returns: FlyweightFactory. The `object` argument turned into the desired type.
    --
    new = function(object)
        object.count = 0
        setmetatable(object, Metatable)
        cLogger:assertField(object, "make")
        cLogger:assertField(object, "valueEquals")
        return object
    end,
}

-- Metatable of the FlyweightFactory class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets the interned object equals to a desired value (creates one if necessary).
        --
        -- Args:
        -- * self: FlyweightFactory.
        -- * data: table. Same fields as the built type. However, it might not have its metatable.
        --
        -- Returns: BuiltType. A reference to the interned object of this factory.
        --
        get = function(self, data)
            local equals = self.valueEquals
            local count = self.count
            for i=1,count do
                local cached = self[i]
                if equals(cached, data) then
                    return cached
                end
            end
            count = count + 1
            local result = self.make(data)
            self[count] = result
            self.count = count
            return result
        end,


        -- Creates an instance of BuiltType for the internal cache.
        --
        -- NOT a method.
        --
        -- Args:
        -- * data: table. Same fields as the built type. Used as constructor arguments.
        --
        -- Returns: BuiltTupe. The new cache entry.
        --[[
        make = function(data) end,
        --]]

        -- Tests the equality of a BuiltType object with some raw data.
        --
        -- NOT a method.
        --
        -- Args:
        -- * cached: BuiltType. Proper object with metatable.
        -- * data: table. Same fields as the built type. However, it might not have its metatable.
        --
        -- Returns: boolean. True if equals, false if different.
        --[[
        valueEquals = function(cached, data) end,
        --]]
    }
}

return FlyweightFactory
