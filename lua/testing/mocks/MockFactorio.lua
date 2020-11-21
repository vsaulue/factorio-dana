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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")

local Metatable

-- Class used to imitate aFactorio environment.
--
-- Implemented globals:
-- * game
-- * global
--
local MockFactorio = ErrorOnInvalidRead.new{
    -- Creates a new MockFactorio object.
    --
    -- Args:
    -- * cArgs: table. May contain the following fields:
    -- **  rawData: table. Raw prototype data from Factorio's data phase.
    --
    -- Returns: The new MockFactorio object.
    --
    make = function(cArgs)
        local result = {
            game = LuaGameScript.make(cArgs.rawData),
            global = {},
        }
        setmetatable(result, Metatable)
        return result
    end,
}

-- Metatable of the MockFactorio class.
Metatable = {
    autoLoaded = true,

    __index = ErrorOnInvalidRead.new{
        -- Creates a new player in the game.
        --
        -- Args:
        -- * self: MockFactorio.
        -- * cArgs: table. See LuaGameScript.createPlayer(cArgs).
        --
        -- Returns: LuaPlayer. The new object.
        --
        createPlayer = function(self, cArgs)
            return LuaGameScript.createPlayer(self.game, cArgs)
        end,

        -- Sets all the global variables to the values in this object.
        --
        -- Args:
        -- * self: MockFactorio.
        --
        setup = function(self)
            _G.game = self.game
            _G.global = self.global
        end,
    }
}

return MockFactorio
