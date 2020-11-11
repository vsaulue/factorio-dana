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

local Metatable
local cLogger

-- Mock implementation of Factorio's LuaGameScript.
--
-- See https://lua-api.factorio.com/1.0.0/LuaSurface.html
--
-- Inherits from CommonMockObject.
--
-- Implemented fields & methods:
-- * index
-- * name
-- + CommonMockObject.
--
local LuaSurface = {
    -- Creates a new LuaSurface object.
    --
    -- Args:
    -- * cArgs: table. May contain the following fields:
    -- **  index
    -- **  name
    make = function(cArgs)
        local selfData = {
            index = cLogger:assertFieldType(cArgs, "index", "number"),
            name = cLogger:assertFieldType(cArgs, "name", "string"),
        }
        return CommonMockObject.make(selfData, Metatable)
    end,
}

-- Metatable of the LuaSurface class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaSurface",

    getters = {
        index = MockGetters.validTrivial("index"),
        name = MockGetters.validTrivial("name"),
    },
}
cLogger = Metatable.cLogger

return LuaSurface
