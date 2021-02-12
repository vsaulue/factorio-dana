-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local AppTestbench = require("lua/testing/AppTestbench")
local AutoLoaded = require("lua/testing/AutoLoaded")
local GuiElement = require("lua/gui/GuiElement")
local QueryEditorInterface = require("lua/apps/query/step/editor/QueryEditorInterface")
local QueryEditorMenu = require("lua/apps/query/step/editor/QueryEditorMenu")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("QueryEditorMenu", function()
    local appTestbench
    local editorInterface
    local parent
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {},
        }
        appTestbench:setup()

        editorInterface = AutoLoaded.new{
            getGuiUpcalls = function()
                return "abcde"
            end,
            setParamsEditor = function() end,
        }
        QueryEditorInterface.checkMethods(editorInterface)

        parent = appTestbench.player.gui.screen
    end)

    local object
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        object = QueryEditorMenu.new{
            editorInterface = editorInterface,
            roots = {
                {
                    caption = "root_1",
                    children = {
                        {
                            caption = "child_1a",
                            selectable = true,
                            editorName = "editor_1a",
                        },{
                            caption = "child_1b",
                            selectable = true,
                            editorName = "editor_1b",
                        },
                    },
                },{
                    caption = "root_2",
                    selectable = true,
                    editorName = "editor_2",
                },
            },
        }
    end)

    it(".new()", function()
        local roots = object.roots
        assert.are.same(object.editorNameToNode, {
            editor_1a = roots[1].children[1],
            editor_1b = roots[1].children[2],
            editor_2 = roots[2],
        })
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = {
                    appTestbench = appTestbench,
                    object = object,
                },
                metatableSetter = function(objects)
                    AppTestbench.setmetatable(objects.appTestbench)
                    QueryEditorMenu.setmetatable(objects.object)
                end,
            }
        end

        it("-- no gui", function()
            runTest()
        end)

        it("-- with gui", function()
            object:open(parent)
            runTest()
        end)
    end)

    it(":getGuiUpcalls()", function()
        spy.on(editorInterface, "getGuiUpcalls")
        local upcalls = object:getGuiUpcalls()

        assert.are.equals(upcalls, editorInterface:getGuiUpcalls())
        assert.spy(editorInterface.getGuiUpcalls).was.called_with(match.is_ref(editorInterface))
    end)

    it(":newRoot()", function()
        local EditorName = "editor_3a"
        object:newRoot{
            caption = "root_3",
            children = {
                {
                    caption = "child_3a",
                    selectable = true,
                    editorName = EditorName,
                },
            },
        }

        local roots = object.roots
        assert.is_not_nil(roots[3])
        assert.are.equals(object.editorNameToNode[EditorName], roots[3].children[1])
    end)

    it(":onSelectionChanged()", function()
        stub(editorInterface, "setParamsEditor")
        object:setSelection(object.roots[1].children[2])
        assert.stub(editorInterface.setParamsEditor).was.called_with(match.is_ref(editorInterface), "editor_1b")
    end)

    describe(":selectByName()", function()
        it("-- valid", function()
            stub(editorInterface, "setParamsEditor")
            object:selectByName("editor_1a")
            assert.are.equals(object.selection, object.roots[1].children[1])
            assert.stub(editorInterface.setParamsEditor).was.called_with(match.is_ref(editorInterface), "editor_1a")

            object:selectByName("editor_1a")
            assert.stub(editorInterface.setParamsEditor).was.called(1)
        end)

        it("-- invalid", function()
            assert.error(function()
                object:selectByName("404")
            end)
        end)
    end)
end)
