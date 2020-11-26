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
local MockObject = require("lua/testing/mocks/MockObject")
local SimpleItemStack = require("lua/testing/mocks/SimpleItemStack")

local cLogger

local Metatable
local forwardTrivial

-- Mock implementation of Factorio's LuaGameScript.
--
-- See https://lua-api.factorio.com/1.0.0/LuaItemStack.html
--
-- Inherits from CommonMockObject.
--
-- Implemented fields & methods:
-- * count
-- * name
-- + CommonMockObject.
--
local LuaItemStack = {
    -- Creates a new LuaItemStack object.
    --
    -- Args:
    -- * args: table. May contain the following fields:
    -- **  slot: ItemSlot. Slot this stack points to.
    --
    -- Returns: LuaItemStack.
    --
    make = function(args)
        local data = {
            slot = cLogger:assertField(args, "slot"),
        }
        return CommonMockObject.make(data, Metatable)
    end,
}

-- Generates a getter that directly  returns ItemSlot:get(index).
--
-- Args:
-- * index: string. Index to pass to ItemSlot:get().
--
-- Returns: The return value of ItemSlot:get().
--
forwardTrivial = function(index)
    return function(self)
        local data = MockObject.getData(self, index)
        return data.slot:get(index)
    end
end

-- Metatable of the LuaItemStack class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaItemStack",

    getters = {
        count = forwardTrivial("count"),
        name = forwardTrivial("name"),

        set_stack = function(self)
            return function(value)
                local data = MockObject.getData(self, "set_stack")
                local newStack = value
                if newStack then
                    local vMetatable = getmetatable(value)
                    if vMetatable then
                        cLogger:assert(vMetatable == Metatable, "Invalid set_stack() argument (LuaStack or SimpleItemStack required).")
                        if not value.valid_for_read then
                            newStack = nil
                        end
                    else
                        newStack = SimpleItemStack.make(value)
                    end
                end
                data.slot:setStack(newStack)
            end
        end,

        valid_for_read = forwardTrivial("valid_for_read"),
    },

    setters = {
        count = function(self, value)
            local data = MockObject.getData(self, "count")
            data.slot:set("count", value)
        end,
    }
}
cLogger = Metatable.cLogger

return LuaItemStack
