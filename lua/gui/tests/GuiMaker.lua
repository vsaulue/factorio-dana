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

local GuiMaker = require("lua/gui/GuiMaker")
local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")

describe("GuiMaker", function()
    local MockArgs = {player_index = 1234}
    local checkClassName = function(object, className)
        assert.are.equals(getmetatable(object).className, className)
    end

    local parent
    before_each(function()
        parent = LuaGuiElement.make({
            type = "flow",
            direction = "horizontal",
        }, MockArgs)
    end)

    it(".run()", function()
        local result = GuiMaker.run(parent, {
            type = "frame",
            direction = "vertical",
            children = {
                {
                    type = "flow",
                    direction = "vertical",
                    children = {
                        {
                            type = "button",
                        },
                    },
                },{
                    type = "line",
                    direction = "horizontal",
                },
            },
        })
        checkClassName(result, "FrameGuiElement")
        checkClassName(result.children[1], "FlowGuiElement")
        checkClassName(result.children[1].children[1], "ButtonGuiElement")
        checkClassName(result.children[2], "LineGuiElement")
    end)
end)
