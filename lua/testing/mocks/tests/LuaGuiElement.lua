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
local MockObject = require("lua/testing/mocks/MockObject")

describe("-- LuaGuiElement", function()
    local PlayerIndex = 1234
    local MockArgs = {player_index = PlayerIndex}

    describe(".make()", function()
        it("-- invalid (no args)", function()
            assert.error(LuaGuiElement.make)
        end)

        it("-- invalid (no type field)", function()
            assert.error(function()
                LuaGuiElement.make({}, MockArgs)
            end)
        end)

        it("-- invalid (unkown type)", function()
            assert.error(function()
                LuaGuiElement.make({
                    type = "foobar",
                }, MockArgs)
            end)
        end)

        it("-- valid", function()
            local element = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
            assert.are.equals(element.player_index, PlayerIndex)
        end)
    end)

    describe(":add()", function()
        local parent
        before_each(function()
            parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
        end)

        it("-- valid", function()
            local child = parent.add{
                type = "flow",
                direction = "vertical",
            }
            assert.are.equals(child.type, "flow")
            assert.are.equals(child.parent, parent)
            assert.are.equals(parent.children[1], child)
            assert.are_not.equals(parent.index, child.index)
        end)

        it("-- valid + name", function()
            local child = parent.add{
                type = "flow",
                direction = "vertical",
                name = "barfoo",
            }
            assert.are.equals(child.type, "flow")
            assert.are.equals(child.parent, parent)
            assert.are.equals(parent.children[1], child)
            assert.are_not.equals(parent.index, child.index)
            assert.are.equals(MockObject.getData(parent).childrenByName.barfoo, child)
        end)

        it("-- error (duplicate name)", function()
            local cArgs = {
                type = "button",
                name = "wololo",
            }
            parent.add(cArgs)
            assert.error(function()
                parent.add(cArgs)
            end)
        end)

        it("-- error (wrong constructor arguments)", function()
            assert.error(function()
                parent.add{
                    type = "compilatron",
                }
            end)
        end)

        it("-- error (invalid parent)", function()
            local child = parent.add{
                type = "frame",
                direction = "horizontal",
            }
            child.destroy()
            assert.error(function()
                child.add{
                    type = "flow",
                    direction = "vertical",
                }
            end)
        end)
    end)

    describe(":auto_center", function()
        it("-- read", function()
            local flow = LuaGuiElement.make({
                type = "flow",
            }, MockArgs)
            local data = MockObject.getData(flow)
            local value = {}
            data.auto_center = value
            assert.are.equals(flow.auto_center, value)
        end)

        it("-- valid write", function()
            local screen = LuaGuiElement.make({
                type = "empty-widget",
            },{
                player_index = PlayerIndex,
                childrenHasLocation = true,
            })
            local child = screen.add{
                type = "frame",
            }
            child.auto_center = true
            assert.is_true(MockObject.getData(child).auto_center)
        end)

        it("-- invalid write", function()
            local screen = LuaGuiElement.make({
                type = "empty-widget",
            }, MockArgs)
            local child = screen.add{
                type = "frame",
            }
            assert.error(function()
                child.auto_center = true
            end)
        end)
    end)

    describe(":caption", function()
        it("-- constructor", function()
            local caption = {"foobar"}
            local element = LuaGuiElement.make({
                type = "label",
                caption = caption,
            }, MockArgs)
            assert.are.equals(MockObject.getData(element).caption, caption)
        end)

        it("-- read", function()
            local caption = {"barfoo"}
            local element = LuaGuiElement.make({
                type = "label",
                caption = caption,
            }, MockArgs)
            assert.are.equals(element.caption, caption)
        end)

        it("--write", function()
            local caption = "MissingNo"
            local element = LuaGuiElement.make({
                type = "label",
            }, MockArgs)
            element.caption = caption
            assert.are.equals(MockObject.getData(element).caption, caption)
        end)
    end)

    describe(":clear()", function()
        it("-- valid", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
            local parent = root.add{
                type = "flow",
                direction = "vertical",
                name = "wololo"
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
            assert.is_nil(next(MockObject.getData(root).childrenByName))
        end)

        it("-- error (invalid self)", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
            local parent = root.add{
                type = "flow",
                direction = "horizontal",
            }
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
            }, MockArgs)
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

        it("-- valid + name", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
            local child = root.add{
                type = "button",
                name = "barfoo",
            }
            child.destroy()

            assert.is_false(child.valid)
            assert.is_nil(MockObject.getData(root).childrenByName.barfoo)
        end)

        it("-- error (invalid self)", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
            local parent = root.add{type = "button"}
            parent.destroy()

            assert.error(function()
                parent.destroy()
            end)
        end)

        it("-- error (root element)", function()
            local root = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)

            assert.error(function()
                root.destroy()
            end)
        end)
    end)

    describe(":force_auto_center()", function()
        it("-- valid", function()
            local root = LuaGuiElement.make({
                type = "empty-widget",
            },{
                player_index = PlayerIndex,
                childrenHasLocation = true,
            })
            local frame = root.add{
                type = "frame",
            }
            frame.force_auto_center()
            local data = MockObject.getData(frame)
            assert.are.same(data.location, {
                x = 12,
                y = 12,
            })
            assert.is_true(data.auto_center)
        end)

        it("-- invalid (not a frame)", function()
            local root = LuaGuiElement.make({
                type = "empty-widget",
            },{
                player_index = PlayerIndex,
                childrenHasLocation = true,
            })
            local flow = root.add{
                type = "flow",
            }
            assert.error(function()
                flow.force_auto_center()
            end)
        end)

        it("-- invalid (no location)", function()
            local root = LuaGuiElement.make({
                type = "empty-widget",
            }, MockArgs)
            local frame = root.add{
                type = "frame",
            }
            assert.error(function()
                frame.force_auto_center()
            end)
        end)
    end)

    describe(":enabled", function()
        local element
        before_each(function()
            element = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
                enabled = false,
            }, MockArgs)
        end)

        it("-- constructor", function()
            assert.is_false(MockObject.getData(element).enabled)
        end)

        it("-- read", function()
            local data = MockObject.getData(element)
            data.enabled = "Spartaaaa"
            assert.are.equals(element.enabled, "Spartaaaa")
        end)

        it("-- write", function()
            element.enabled = true
            assert.is_true(MockObject.getData(element).enabled)
        end)
    end)

    describe(":location", function()
        local parent
        local child
        before_each(function()
            parent = LuaGuiElement.make({
                type = "empty-widget",
            }, {
                player_index = PlayerIndex,
                childrenHasLocation = true,
            })

            child = parent.add{
                type = "frame",
                direction = "vertical",
            }
        end)

        it("-- constructor", function()
            assert.is_nil(MockObject.getData(parent).location)
            assert.are.same(MockObject.getData(child).location, {x=0,y=0})
        end)

        it("-- read", function()
            assert.is_nil(parent.location)
            assert.are.same(child.location, {x=0,y=0})
        end)

        it("-- write (no location)", function()
            parent.location = {5,5}
            assert.is_nil(MockObject.getData(parent).location)
        end)

        it("-- write (array)", function()
            child.location = {8,9}
            assert.are.same(MockObject.getData(child).location, {
                x = 8,
                y = 9,
            })
        end)

        it("-- write (x=,y=)", function()
            child.location = {x=-7,y=4}
            assert.are.same(MockObject.getData(child).location, {
                x = -7,
                y = 4,
            })
        end)
    end)

    describe(":name", function()
        local cArgs
        before_each(function()
            cArgs = {
                type = "button",
                name = "kilroy",
            }
        end)

        describe("-- constructor:", function()
            it("valid", function()
                local element = LuaGuiElement.make(cArgs, MockArgs)
                assert.are.equals(MockObject.getData(element).name, "kilroy")
            end)

            it("invalid", function()
                cArgs.name = 7
                assert.error(function()
                    LuaGuiElement.make(cArgs, MockArgs)
                end)
            end)
        end)

        it("-- read", function()
            local element = LuaGuiElement.make(cArgs, MockArgs)
            assert.are.equals(element.name, "kilroy")
        end)
    end)

    describe(".style", function()
        describe("-- constructor:", function()
            it("valid", function()
                local element = LuaGuiElement.make({
                    type = "flow",
                    direction = "vertical",
                    style = "kilroy",
                }, MockArgs)
                assert.are.equals(MockObject.getData(element).style.name, "kilroy")
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
                }, MockArgs)
            end)

            it("-- valid read", function()
                assert.are.equals(element.style, MockObject.getData(element).style)
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
            }, MockArgs)
            assert.is_true(MockObject.getData(element).visible)
        end)

        it("-- read", function()
            local element = LuaGuiElement.make({
                type = "label",
            }, MockArgs)
            assert.is_false(element.visible)
        end)

        it("--write", function()
            local element = LuaGuiElement.make({
                type = "label",
            }, MockArgs)
            element.visible = true
            assert.is_true(MockObject.getData(element).visible)
        end)
    end)

    describe(":?? -- string,", function()
        local parent
        local child
        before_each(function()
            parent = LuaGuiElement.make({
                type = "flow",
                direction = "vertical",
            }, MockArgs)
            child = parent.add{
                type = "label",
                name = "PraiseTheSun",
            }
        end)

        it("valid child", function()
            assert.are.equals(parent.PraiseTheSun, child)
        end)

        it("unknown name", function()
            assert.is_nil(parent.PraiseTheMoon)
        end)
    end)

    it(":?? -- invalid field", function()
        local flow = LuaGuiElement.make({
            type = "flow",
            direction = "vertical",
        }, MockArgs)
        assert.error(function()
            print(flow[1])
        end)
    end)
end)
