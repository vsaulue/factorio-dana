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
local MockMetatableParams = require("lua/testing/mocks/MockMetatableParams")

local cLogger = ClassLogger.new{className = "MockMetatable"}

local makeSubclassIndex
local makeSubclassNewIndex
local Metatable

-- Class for metatables used in the Mock framework.
--
-- RO Fields:
-- * autoLoaded: boolean. Flag set for SaveLoadTester (should be always true).
-- * className: string. Name of this class (preferably unique, but not necessary).
-- * cLogger: ClassLogger. Logger for the objects using this metatable.
-- * __index: function.
-- * __newindex: function.
--
local MockMetatable = {
    -- Creates a new MockMetatable object.
    --
    -- Args:
    -- * object: Table to turn into a MockMetatable object.
    --
    -- Returns: The argument turned into a MockMetatable object.
    --
    new = function(object)
        local className = cLogger:assertFieldType(object, "className", "string")
        cLogger:assertFieldType(object, "__index", "function")
        cLogger:assertFieldType(object, "__newindex", "function")
        object.autoLoaded = true
        object.cLogger = ClassLogger.new{className = className}
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the MockMetatable class.
Metatable = {
    __index = {
        -- Creates a new MockMetatable, for a derived type.
        --
        -- This will automatically chains the __index & __newindex calls.
        --
        -- Args:
        -- * self: MockMetatable.
        -- * params: MockMetatableParams. Parameters of the derived type.
        --
        -- Returns: MockMetatable. The new derived metatable.
        --
        makeSubclass = function(self, params)
            MockMetatableParams.check(params)
            return MockMetatable.new{
                className = params.className,
                __index = makeSubclassIndex(self, params),
                __newindex = makeSubclassNewIndex(self, params),
            }
        end,
    },
}

-- Creates the __index metamethod for a subclass.
--
-- Args:
-- * base: MockMetatable. Metatable to use as parent.
-- * params: MockMetatableParams. Parameters of the derived type.
--
-- Returns: function(*,*) -> *. The __index function for the subclass.
--
makeSubclassIndex = function(base, params)
    local baseIndex = base.__index
    local getters = params.getters
    local fallbackGetter = params.fallbackGetter
    return function(self, index)
        if getters then
            local getter = getters[index]
            if getter then
                return getter(self)
            end
        end
        if fallbackGetter then
            local success,result = fallbackGetter(self, index)
            if success then
                return result
            end
        end
        return baseIndex(self, index)
    end
end

-- Creates the __newindex metamethod for a subclass.
--
-- Args:
-- * base: MockMetatable. Metatable to use as parent.
-- * params: MockMetatableParams. Parameters of the derived type.
--
-- Returns: function(*,*,*) -> *. The __newindex function for the subclass.
--
makeSubclassNewIndex = function(base, params)
    local baseNewIndex = base.__newindex
    local setters = params.setters
    return function(self, index, value)
        if setters then
            local setter = setters[index]
            if setter then
                setter(self, value)
                return
            end
        end
        baseNewIndex(self, index, value)
    end
end

return MockMetatable
