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
local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")
local MockGetters = require("lua/testing/mocks/MockGetters")

local cLogger
local Metatable

local Roots

-- Mock implementation of Factorio's LuaForce.
--
-- See https://lua-api.factorio.com/1.0.0/LuaGui.html
--
-- Implemented fields & methods:
-- * center
-- * goal
-- * left
-- * player
-- * screen
-- * top
-- + CommonMockObject
--
local LuaGui = {
    -- Creates a new LuaGui object
    --
    -- Args:
    -- * cArgs: table. May contain the following fields:
    -- **  player: LuaPlayer.
    --
    -- Returns: The new LuaGui object
    --
    make = function(cArgs)
        local data = {
            player = cLogger:assertFieldType(cArgs, "player", "table"),
        }
        local GuiMockData = {player_index = data.player.index}
        for rootName,rootInfo in pairs(Roots) do
            GuiMockData.childrenHasLocation = rootInfo.childrenHasLocation
            data[rootName] = LuaGuiElement.make(rootInfo, GuiMockData)
        end
        return CommonMockObject.make(data, Metatable)
    end,
}

-- Map[string]: table. Constructor argument of the roots LuaGuiElement, indexed by their names.
Roots = {
    center = {type = "flow", direction = "horizontal"},
    goal = {type = "flow", direction = "horizontal"},
    left = {type = "flow", direction = "horizontal"},
    screen = {type = "empty-widget", childrenHasLocation = true},
    top = {type = "flow", direction = "horizontal"},
}

-- Generates the getters of this class.
--
-- Returns: table. The getters table of LuaGui.
--
local makeGetters = function()
    local result = {
        player = MockGetters.validTrivial("player"),
    }
    for rootName in pairs(Roots) do
        result[rootName] = MockGetters.validTrivial(rootName)
    end
    return result
end

-- Metatable of the LuaGui class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaGui",
    getters = makeGetters(),
}
cLogger = Metatable.cLogger

return LuaGui
