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

local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")
local MockObject = require("lua/testing/mocks/MockObject")

describe("--[[Mock]] FrameGuiElement", function()
    local MockArgs = {player_index = 5678}

    describe(".make", function()
        it("-- valid", function()
            local frame = LuaGuiElement.make({
                type = "frame",
            }, MockArgs)
            assert.are.equals(MockObject.getData(frame).direction, "horizontal")
        end)

        it("-- error (invalid direction)", function()
            assert.error(function()
                LuaGuiElement.make({
                    type = "frame",
                    direction = "kilroy",
                }, MockArgs)
            end)
        end)
    end)

    describe(".direction", function()
        it("-- read (valid)", function()
            local frame = LuaGuiElement.make({
                type = "frame",
                direction = "vertical",
            }, MockArgs)
            assert.are.equals(frame.direction, "vertical")
        end)

        it("-- invalid write", function()
            local frame = LuaGuiElement.make({
                type = "frame",
                direction = "horizontal",
            }, MockArgs)
            assert.error(function()
                frame.direction = "vertical"
            end)
        end)
    end)

    it(".?? (parent field)", function()
        local frame = LuaGuiElement.make({
            type = "frame",
            direction = "vertical",
            caption = "AYBABTU",
        }, MockArgs)
        assert.are.equals(frame.caption, "AYBABTU")
    end)
end)
