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

local MockObject = require("lua/testing/mocks/MockObject")
local ScrollPaneGuiElement = require("lua/testing/mocks/ScrollPaneGuiElement")

describe("ScrollPaneGuiElement", function()
    local mockArgs = {player_index = 4321}

    describe('.make()', function()
        local cArgs
        before_each(function()
            cArgs = {
                type = "scroll-pane",
                horizontal_scroll_policy = "always",
                vertical_scroll_policy = "auto-and-reserve-space",
            }
        end)

        it("-- valid, 2 policies set", function()
            local object = ScrollPaneGuiElement.make(cArgs, mockArgs)
            local data = MockObject.getData(object)
            assert.are.equals(data.horizontal_scroll_policy, "always")
            assert.are.equals(data.vertical_scroll_policy, "auto-and-reserve-space")
        end)

        it("-- valid, default policy", function()
            cArgs.vertical_scroll_policy = nil
            local object = ScrollPaneGuiElement.make(cArgs, mockArgs)
            local data = MockObject.getData(object)
            assert.are.equals(data.horizontal_scroll_policy, "always")
            assert.are.equals(data.vertical_scroll_policy, "auto")
        end)

        it("-- invalid policy", function()
            cArgs.horizontal_scroll_policy = "denied"
            assert.error(function()
                ScrollPaneGuiElement.make(cArgs, mockArgs)
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = ScrollPaneGuiElement.make({
                type = "scroll-pane",
                horizontal_scroll_policy = "always",
                vertical_scroll_policy = "auto-and-reserve-space",
            }, mockArgs)
        end)

        describe(":horizontal_scroll_policy", function()
            it("-- read", function()
                assert.are.equals(object.horizontal_scroll_policy, "always")
            end)

            it("-- valid write", function()
                object.horizontal_scroll_policy = "auto"
                assert.are.equals(MockObject.getData(object).horizontal_scroll_policy, "auto")
            end)

            it("-- invalid write", function()
                assert.error(function()
                    object.horizontal_scroll_policy = "denied"
                end)
            end)
        end)

        describe(":vertical_scroll_policy", function()
            it("-- read", function()
                assert.are.equals(object.vertical_scroll_policy, "auto-and-reserve-space")
            end)

            it("-- valid write", function()
                object.vertical_scroll_policy = "auto"
                assert.are.equals(MockObject.getData(object).vertical_scroll_policy, "auto")
            end)

            it("-- invalid write", function()
                assert.error(function()
                    object.vertical_scroll_policy = "denied"
                end)
            end)
        end)
    end)
end)
