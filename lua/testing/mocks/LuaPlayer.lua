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
local ItemSlot = require("lua/testing/mocks/ItemSlot")
local LuaItemStack = require("lua/testing/mocks/LuaItemStack")
local LuaGui = require("lua/testing/mocks/LuaGui")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger
local lastIndex
local makeIndex
local Metatable

-- Mock implementation of Factorio's LuaItemPrototype.
--
-- See https://lua-api.factorio.com/1.1.0/LuaItemPrototype.html
--
-- Inherits from AbstractPrototype.
--
-- Implemented fields & methods:
-- * clear_cursor()
-- * cursor_stack
-- * force
-- * gui
-- * index
-- + AbstractPrototype.
--
local LuaPlayer = {
    -- Creates a new LuaPlayer object.
    --
    -- Args:
    -- * cArgs: table. May contain the following fields:
    -- **  force: LuaForce.
    --
    -- Returns: LuaPlayer.
    --
    make = function(cArgs)
        local cursorSlot = ItemSlot.new()
        local selfData = {
            cursorSlot = cursorSlot,
            cursor_stack = LuaItemStack.make{slot = cursorSlot},
            force = cLogger:assertFieldType(cArgs, "force", "table"),
            index = makeIndex(),
        }
        local result = CommonMockObject.make(selfData, Metatable)
        selfData.gui = LuaGui.make{player = result}
        return result
    end,
}

-- Metatable of the LuaPlayer class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaPlayer",

    getters = {
        clear_cursor = function(self)
            return function()
                local data = MockObject.getData(self, "clear_cursor")
                -- Note: should try to place the stack back into hand_location, or the main inventory.
                -- & return true only if the stack could be placed back.
                data.cursorSlot:setStack()
                return true
            end
        end,

        cursor_stack = MockGetters.validTrivial("cursor_stack"),
        force = MockGetters.validTrivial("force"),
        gui = MockGetters.validTrivial("gui"),
        index = MockGetters.validTrivial("index"),
    },
}
cLogger = Metatable.cLogger

-- int. Last generated value for the "index" field.
lastIndex = 0

-- Generates a unique value for the "index" field.
--
-- Returns: int.
--
makeIndex = function()
    lastIndex = lastIndex + 1
    return lastIndex
end

return LuaPlayer
