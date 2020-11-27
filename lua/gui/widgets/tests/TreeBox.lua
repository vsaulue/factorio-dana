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

local AutoLoaded = require("lua/testing/AutoLoaded")
local GuiElement = require("lua/gui/GuiElement")
local GuiUpcalls = require("lua/gui/GuiUpcalls")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TreeBox = require("lua/gui/widgets/TreeBox")

local makeUpcalls = function()
    local result = AutoLoaded.new{
        notifyGuiCorrupted = function() end,
    }
    GuiUpcalls.checkMethods(result)
    return result
end

describe("TreeBox", function()
    local factorio
    local player
    local parent
    local upcalls
    setup(function()
        factorio = MockFactorio.make{
            rawData = {},
        }
        player = factorio:createPlayer{
            forceName = "player",
        }
        parent = player.gui.center
        factorio:setup()

        upcalls = makeUpcalls()
    end)

    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        controller = TreeBox.new{
            roots = {
                {
                    caption = "top1",
                    children = {
                        {
                            caption = "child_1a",
                            children = {
                                {
                                    caption = "child_1aa",
                                    selectable = true,
                                },
                            },
                        },{
                            caption = "child_1b",
                        },
                    },
                    expanded = true,
                },{
                    caption = "top2",
                    selectable = true,
                }
            },
            upcalls = upcalls,
        }
    end)

    it(".new()", function()
        assert.are.same(controller, {
            roots = {
                count = 2,
                [1] = {
                    caption = "top1",
                    children = {
                        count = 2,
                        [1] = {
                            caption = "child_1a",
                            children = {
                                count = 1,
                                [1] = {
                                    caption = "child_1aa",
                                    children = {count = 0},
                                    depth = 2,
                                    expanded = false,
                                    isLast = true,
                                    selectable = true,
                                    selected = false,
                                    treeBox = controller,
                                },
                            },
                            depth = 1,
                            expanded = false,
                            isLast = false,
                            selectable = false,
                            selected = false,
                            treeBox = controller,
                        },
                        [2] = {
                            caption = "child_1b",
                            children = {count = 0},
                            depth = 1,
                            expanded = false,
                            isLast = true,
                            selectable = false,
                            selected = false,
                            treeBox = controller,
                        },
                    },
                    depth = 0,
                    expanded = true,
                    isLast = false,
                    selectable = false,
                    selected = false,
                    treeBox = controller,
                },
                [2] = {
                    caption = "top2",
                    children = {count = 0},
                    depth = 0,
                    expanded = false,
                    isLast = true,
                    selectable = true,
                    selected = false,
                    treeBox = controller,
                },
            },
            upcalls = upcalls,
        })
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = controller,
                metatableSetter = TreeBox.setmetatable,
            }
        end
        it("-- no gui", function()
            runTest()
        end)

        it("-- with gui", function()
            controller:open(parent)
            runTest()
        end)
    end)

    it(":close()", function()
        controller:open(parent)
        controller:close()
        assert.is_nil(rawget(controller, "gui"))
        assert.is_nil(rawget(controller.roots[1], "gui"))
        assert.is_nil(parent.children[1])
        assert.are.equals(GuiElement.count(player.index), 0)
        controller:close()
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(upcalls, controller:getGuiUpcalls())
    end)

    it(":gui:isValid()", function()
        controller:open(parent)
        local gui = controller.gui
        assert.is_true(gui:isValid())
        controller:close()
        assert.is_false(gui:isValid())
    end)

    it(":open()", function()
        controller:open(parent)
        assert.are.same(controller.gui, {
            flow = parent.children[1],
            parent = parent,
            controller = controller,
        })
    end)

    describe(":setSelection() -- not selectable", function()
        controller:setSelection(controller.roots[1])
        assert.is_nil(rawget(controller, "selection"))
    end)
end)

describe("TreeBoxNode", function()
    local factorio
    local player
    local parent
    local upcalls
    setup(function()
        factorio = MockFactorio.make{
            rawData = {},
        }
        player = factorio:createPlayer{
            forceName = "player",
        }
        parent = player.gui.center
        factorio:setup()

        upcalls = makeUpcalls()
    end)

    local treeBox
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        treeBox = TreeBox.new{
            roots = {
                {
                    caption = "first",
                    children = {
                        {
                            caption = "first_1",
                            selectable = true,
                        },
                    },
                    expanded = true,
                },{
                    caption = "second",
                    children = {
                        {
                            caption = "second_1",
                            selectable = true,
                        },{
                            caption = "second_2",
                            selectable = true,
                        },
                    },
                    expanded = false,
                },
            },
            upcalls = upcalls,
        }
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(upcalls, treeBox.roots[2]:getGuiUpcalls())
    end)

    it(":gui:isValid()", function()
        treeBox:open(parent)
        local gui = treeBox.roots[1].gui
        assert.is_true(gui:isValid())
        treeBox:close()
        assert.is_false(gui:isValid())
    end)

    describe(":setSelected()", function()
        it("-- no gui", function()
            local node = treeBox.roots[1].children[1]
            node:setSelected(true)
            assert.is_true(node.selected)
        end)

        describe("-- gui", function()
            before_each(function()
                treeBox:open(parent)
            end)

            it(", true & selectable", function()
                local node = treeBox.roots[2].children[1]
                node:setSelected(true)
                assert.is_true(node.selected)
                local selectStyle = node.gui.selectLabel.rawElement.style
                assert.are.equals(selectStyle.font, "default-bold")
                assert.are_not.equals(selectStyle.font_color[1], 1)
            end)

            it(", true & not selectable", function()
                local node = treeBox.roots[1]
                node:setSelected(true)
                assert.is_false(node.selected)
            end)

            it(", false", function()
                local node = treeBox.roots[2].children[1]
                node:setSelected(false)
                assert.is_false(node.selected)
                local selectStyle = node.gui.selectLabel.rawElement.style
                assert.are.equals(selectStyle.font, "default")
                assert.are.equals(selectStyle.font_color[1], 1)
            end)
        end)
    end)

    describe(":toggleExpanded()", function()
        describe("-- no gui", function()
            it(", true -> false", function()
                local node = treeBox.roots[1]
                node:toggleExpanded()
                assert.is_false(node.expanded)
            end)

            it(", false -> true", function()
                local node = treeBox.roots[2]
                node:toggleExpanded()
                assert.is_true(node.expanded)
            end)
        end)

        describe("-- with gui", function()
            before_each(function()
                treeBox:open(parent)
            end)

            it(", true -> false", function()
                local node = treeBox.roots[1]
                node:toggleExpanded()
                assert.is_false(node.expanded)
                assert.is_false(node.gui.childrenFlow.visible)
                assert.are.equals(node.gui.headerFlow.children[1].caption, "▶ ")
            end)

            it(", false -> true", function()
                local node = treeBox.roots[2]
                node:toggleExpanded()
                assert.is_true(node.expanded)
                assert.is_true(node.gui.childrenFlow.visible)
                assert.are.equals(node.gui.headerFlow.children[1].caption, "▼ ")
            end)
        end)
    end)

    describe("-- GUI:", function()
        before_each(function()
            treeBox:open(parent)
        end)

        it("ExpandLabel", function()
            GuiElement.on_gui_click{
                player_index = player.index,
                element = treeBox.roots[1].gui.headerFlow.children[1],
            }
            assert.is_false(treeBox.roots[1].expanded)
        end)

        it("SelectLabel", function()
            GuiElement.on_gui_click{
                player_index = player.index,
                element = treeBox.roots[2].children[1].gui.headerFlow.children[3],
            }
            assert.is_true(treeBox.roots[2].children[1].selected)

            GuiElement.on_gui_click{
                player_index = player.index,
                element = treeBox.roots[1].children[1].gui.headerFlow.children[3]
            }
            assert.is_true(treeBox.roots[1].children[1].selected)
            assert.is_false(treeBox.roots[2].children[1].selected)
        end)
    end)
end)
