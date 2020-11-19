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

local ChooseElemGuiElement = require("lua/testing/mocks/ChooseElemGuiElement")
local MockObject = require("lua/testing/mocks/MockObject")

describe("ChooseElemGuiElement", function()
    local MockArgs = {player_index = 1234}

    describe(".make()", function()
        local cArgs
        before_each(function()
            cArgs = {
                type = "choose-elem-button",
                elem_type = "item",
            }
        end)

        it("-- valid, no value", function()
            local object = ChooseElemGuiElement.make(cArgs, MockArgs)
            local data = MockObject.getData(object)
            assert.are.equals(data.elem_type, "item")
            assert.are.equals(data.type, "choose-elem-button")
        end)

        it("-- valid, value", function()
            cArgs.elem_value = "coal"
            local object = ChooseElemGuiElement.make(cArgs, MockArgs)
            local data = MockObject.getData(object)
            assert.are.equals(data.elem_type, "item")
            assert.are.equals(data.elem_value, "coal")
            assert.are.equals(data.type, "choose-elem-button")
        end)

        it("-- missing elem_type", function()
            cArgs.elem_type = nil
            assert.error(function()
                ChooseElemGuiElement.make(cArgs, MockArgs)
            end)
        end)

        it("-- invalid elem_type", function()
            cArgs.elem_type = "foobar"
            assert.error(function()
                ChooseElemGuiElement.make(cArgs, MockArgs)
            end)
        end)

        it("-- invalid elem_value", function()
            cArgs.elem_value = 1234
            assert.error(function()
                ChooseElemGuiElement.make(cArgs, MockArgs)
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = ChooseElemGuiElement.make({
                type = "choose-elem-button",
                elem_type = "fluid",
                elem_value = "water",
            }, MockArgs)
        end)

        describe(":elem_type", function()
            it("-- read", function()
                assert.are.equals(object.elem_type, "fluid")
            end)

            it("-- write", function()
                assert.error(function()
                    object.elem_type = "denied"
                end)
            end)
        end)

        describe(":elem_value", function()
            it("-- read", function()
                assert.are.equals(object.elem_value, "water")
            end)

            it("-- valid write (string)", function()
                object.elem_value = "steam"
                assert.are.equals(MockObject.getData(object).elem_value, "steam")
            end)

            it("-- valid write (nil)", function()
                object.elem_value = nil
                assert.is_nil(MockObject.getData(object).elem_value)
            end)

            it("-- invalid write", function()
                assert.error(function()
                    object.elem_value = {}
                end)
            end)
        end)
    end)
end)
