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
local TextfieldGuiElement = require("lua/testing/mocks/TextfieldGuiElement")

describe("TextfieldGuiElement", function()
    local MockArgs = {player_index = 1234}

    describe(".make()", function()
        local cArgs
        before_each(function()
            cArgs = {
                type = "textfield",
                text = "12345",
                allow_negative = true,
                numeric = true,
            }
        end)

        it("-- valid", function()
            local object = TextfieldGuiElement.make(cArgs, MockArgs)
            local data = MockObject.getData(object)
            assert.are.equals(data.text, "12345")
            assert.is_true(data.numeric)
            assert.is_true(data.allow_negative)
        end)

        it("-- valid, no text", function()
            cArgs.text = nil
            local object = TextfieldGuiElement.make(cArgs, MockArgs)
            assert.are.equals(MockObject.getData(object).text, "")
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = TextfieldGuiElement.make({
                type = "textfield",
                text = "foobar",
            }, MockArgs)
        end)

        describe(":allow_negative", function()
            it("-- read", function()
                local data = MockObject.getData(object)
                data.allow_negative = "fake"
                assert.are.equals(object.allow_negative, "fake")
            end)

            it("-- write", function()
                local data = MockObject.getData(object)
                data.text = "-1"
                data.numeric = true
                object.allow_negative = false
                assert.is_false(data.allow_negative)
                assert.are.equals(data.text, "")
            end)
        end)

        describe(":numeric", function()
            it("-- read", function()
                local data = MockObject.getData(object)
                data.numeric = "fake"
                assert.are.equals(object.numeric, "fake")
            end)

            it("-- write", function()
                local data = MockObject.getData(object)
                object.numeric = true
                assert.is_true(data.numeric)
                assert.are.equals(data.text, "")
            end)
        end)

        describe(":text", function()
            it("-- read", function()
                assert.are.equals(object.text, "foobar")
            end)

            it("-- write, text", function()
                object.text = "barfoo"
                assert.are.equals(MockObject.getData(object).text, "barfoo")
            end)

            it("-- write, invalid numeric", function()
                object.numeric = true
                object.text = "nope"
                assert.are.equals(MockObject.getData(object).text, "")
            end)

            it("-- write, invalid negative", function()
                object.allow_negative = false
                object.numeric = true
                object.text = "-5"
                assert.are.equals(MockObject.getData(object).text, "")
            end)
        end)
    end)
end)
