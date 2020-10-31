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

local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger
local Metatable

-- Mock implementation of Factorio's LuaRecipe.
--
-- See https://lua-api.factorio.com/1.0.0/LuaRecipe.html
--
-- Implemented fields & methods:
-- * force
-- * name
-- * prototype
-- + CommonMockObject
--
local LuaRecipe = {
    -- Creates a new LuaRecipe object.
    --
    -- Args:
    -- * selfData: table. Internal table used in the MockObject (required fields: force, prototype).
    --
    -- Returns: The new LuaRecipe object.
    --
    make = function(selfData)
        cLogger:assertFieldType(selfData, "force", "table")
        cLogger:assertFieldType(selfData, "prototype", "table")
        return CommonMockObject.make(selfData, Metatable)
    end,
}

-- Metatable of the LuaRecipe class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaRecipe",

    getters = {
        force = MockGetters.validTrivial("force"),
        name = function(self)
            local data = MockObject.getData(self)
            return data.prototype.name
        end,
        prototype = MockGetters.validTrivial("prototype"),
    },
}

cLogger = Metatable.cLogger

return LuaRecipe
