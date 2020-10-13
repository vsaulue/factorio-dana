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

local PlayerIndex = 5678

describe("--[[Mock]] FlowGuiElement", function()
    describe(".make", function()
        it("-- error (no direction)", function()
            assert.error(function()
                LuaGuiElement.make({
                    type = "flow",
                }, PlayerIndex)
            end)
        end)

        it("-- error (invalid direction)", function()
            assert.error(function()
                LuaGuiElement.make({
                    type = "flow",
                    direction = "kilroy",
                }, PlayerIndex)
            end)
        end)
    end)

    describe(".direction", function()
        it("-- read (valid)", function()
            local flow = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            assert.are.equals(flow.direction, "vertical")
        end)

        it("-- invalid write", function()
            local flow = LuaGuiElement.make({
                type = "flow",
                direction = "horizontal",
            }, PlayerIndex)
            assert.error(function()
                flow.direction = "vertical"
            end)
        end)
    end)
end)
