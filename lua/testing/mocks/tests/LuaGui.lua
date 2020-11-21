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

local LuaGui = require("lua/testing/mocks/LuaGui")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaGui", function()
    local player
    local object
    before_each(function()
        player = {
            index = 159,
        }
        object = LuaGui.make{
            player = player,
        }
    end)

    it(".make()", function()
        local data = MockObject.getData(object)
        assert.are.equals(data.player, player)
        assert.is_not_nil(data.center)
        assert.is_not_nil(data.goal)
        assert.is_not_nil(data.left)
        assert.is_not_nil(data.screen)
        assert.is_not_nil(data.top)
    end)

    local runFieldTest = function(index)
        local data = MockObject.getData(object)
        assert.are.equals(data[index], object[index])
    end

    local runElementFieldTest = function(index)
        runFieldTest(index)
        local elementData = MockObject.getData(object[index])
        assert.are.equals(elementData.childrenHasLocation, index == "screen")
    end

    it(":center", function()
        runElementFieldTest("center")
    end)

    it(":goal", function()
        runElementFieldTest("goal")
    end)

    it(":left", function()
        runElementFieldTest("left")
    end)

    it(":player", function()
        runFieldTest("player")
    end)

    it(":screen", function()
        runElementFieldTest("screen")
    end)

    it(":top", function()
        runElementFieldTest("top")
    end)
end)
