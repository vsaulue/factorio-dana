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

local AbstractGuiElement = require("lua/testing/mocks/AbstractGuiElement")
local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")

local PlayerIndex = 1234

describe("--[[Mock]] LuaGuiElement", function()
    describe(".make()", function()
        it("-- invalid (no args)", function()
            assert.error(LuaGuiElement.make)
        end)

        it("-- invalid (no type field)", function()
            assert.error(function()
                LuaGuiElement.make({}, PlayerIndex)
            end)
        end)

        it("-- invalid (unkown type)", function()
            assert.error(function()
                LuaGuiElement.make({
                    type = "foobar",
                }, PlayerIndex)
            end)
        end)

        it("-- valid", function()
            local element = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            assert.are.equals(element.player_index, PlayerIndex)
        end)
    end)

    describe(":add()", function()
        it("-- valid", function()
            local parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            local child = parent.add{
                type = "flow",
                direction = "vertical",
            }
            assert.are.equals(child.type, "flow")
            assert.are.equals(child.parent, parent)
            assert.are.equals(parent.children[1], child)
            assert.are_not.equals(parent.index, child.index)
        end)

        it("-- error (wrong constructor arguments)", function()
            local parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            assert.error(function()
                parent.add{
                    type = "compilatron",
                }
            end)
        end)

        it("-- error (invalid parent)", function()
            local parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            parent.destroy()
            assert.error(function()
                parent.add{
                    type = "flow",
                    direction = "vertical",
                }
            end)
        end)
    end)

    describe(":caption", function()
        it("-- constructor", function()
            local caption = {"foobar"}
            local element = LuaGuiElement.make({
                type = "label",
                caption = caption,
            }, PlayerIndex)
            assert.are.equals(AbstractGuiElement.getDataIfValid(element).caption, caption)
        end)

        it("-- read", function()
            local caption = {"barfoo"}
            local element = LuaGuiElement.make({
                type = "label",
                caption = caption,
            }, PlayerIndex)
            assert.are.equals(element.caption, caption)

            element.destroy()
            assert.error(function()
                print(element.caption)
            end)
        end)

        it("--write", function()
            local caption = "MissingNo"
            local element = LuaGuiElement.make({
                type = "label",
            }, PlayerIndex)
            element.caption = caption
            assert.are.equals(AbstractGuiElement.getDataIfValid(element).caption, caption)

            element.destroy()
            assert.error(function()
                element.caption = caption
            end)
        end)
    end)

    describe(":clear()", function()
        it("-- valid", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            local parent = root.add{
                type = "flow",
                direction = "vertical",
            }
            local child = parent.add{
                type = "flow",
                direction = "vertical",
            }

            root.clear()

            assert.is_false(parent.valid)
            assert.is_false(child.valid)
            assert.is_true(root.valid)
            assert.is_nil(root.children[1])
        end)

        it("-- error (invalid self)", function()
            local parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            parent.destroy()

            assert.error(function()
                parent.clear()
            end)
        end)
    end)

    describe(":destroy()", function()
        it("-- valid", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            local bro = root.add{
                type = "flow",
                direction = "vertical",
            }
            local parent = root.add{
                type = "flow",
                direction = "vertical",
            }
            local child = parent.add{
                type = "flow",
                direction = "vertical",
            }
            parent.destroy()

            assert.is_false(parent.valid)
            assert.is_false(child.valid)
            assert.is_true(root.valid)
            assert.are.equals(root.children[1], bro)
            assert.is_nil(root.children[2])
        end)

        it("-- error (invalid self)", function()
            local parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, PlayerIndex)
            parent.destroy()

            assert.error(function()
                parent.destroy()
            end)
        end)
    end)

    describe(".style", function()
        describe("-- constructor:", function()
            it("valid", function()
                local element = LuaGuiElement.make({
                    type = "flow",
                    direction = "vertical",
                    style = "kilroy",
                }, PlayerIndex)
                assert.are.equals(AbstractGuiElement.getDataIfValid(element).style.name, "kilroy")
            end)

            it("invalid", function()
                assert.error(function()
                    LuaGuiElement.make({
                        type = "flow",
                        direction = "vertical",
                        style = { name = "kilroy"},
                    })
                end)
            end)
        end)

        describe("-- access:", function()
            local element

            before_each(function()
                element = LuaGuiElement.make({
                    type = "flow",
                    direction = "horizontal",
                }, PlayerIndex)
            end)

            it("-- valid read", function()
                assert.are.equals(element.style, AbstractGuiElement.getDataIfValid(element).style)
            end)

            it("-- valid write", function()
                element.style = "foobar"
                assert.are.equals(element.style.name, "foobar")
            end)

            it("-- invalid write", function()
                assert.error(function()
                    element.style = {name = "foobar"}
                end)
            end)
        end)
    end)

    describe(".visible", function()
        it("-- constructor", function()
            local element = LuaGuiElement.make({
                type = "label",
                visible = true,
            }, PlayerIndex)
            assert.is_true(AbstractGuiElement.getDataIfValid(element).visible)
        end)

        it("-- read", function()
            local element = LuaGuiElement.make({
                type = "label",
            }, PlayerIndex)
            assert.is_false(element.visible)

            element.destroy()
            assert.error(function()
                print(element.visible)
            end)
        end)

        it("--write", function()
            local element = LuaGuiElement.make({
                type = "label",
            }, PlayerIndex)
            element.visible = true
            assert.is_true(AbstractGuiElement.getDataIfValid(element).visible)

            element.destroy()
            assert.error(function()
                element.visible = visible
            end)
        end)
    end)

    it(".?? -- invalid field", function()
        local flow = LuaGuiElement.make({
            type = "flow",
            direction = "vertical",
        }, PlayerIndex)
        assert.error(function()
            print(flow.DIRECTION)
        end)
    end)
end)
