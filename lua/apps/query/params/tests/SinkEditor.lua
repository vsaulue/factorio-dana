-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local GuiElement = require("lua/gui/GuiElement")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local SinkEditor = require("lua/apps/query/params/SinkEditor")
local SinkParams = require("lua/query/params/SinkParams")

describe("SinkEditor + GUI", function()
    local appTestbench
    local parent
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {},
        }
        appTestbench:setup()
        parent = appTestbench.player.gui.screen
    end)

    local controller
    local params
    before_each(function()
        GuiElement.on_init()
        parent.clear()

        params = SinkParams.new()
        controller = SinkEditor.new{
            appResources = appTestbench.appResources,
            params = params,
        }
    end)

    it(".new()", function()
        assert.are.same(controller, {
            appResources = appTestbench.appResources,
            editorName = "SinkEditor",
            params = params,
        })
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = {
                    appTestbench = appTestbench,
                    controller = controller,
                    params = params,
                },
                metatableSetter = function(objects)
                    AppTestbench.setmetatable(objects.appTestbench)
                    SinkEditor.setmetatable(objects.controller)
                    SinkParams.setmetatable(objects.params)
                end,
            }
        end

        it("-- no GUI", function()
            runTest()
        end)

        it("-- with GUI", function()
            controller:open(parent)
            runTest()
        end)
    end)

    it(":close()", function()
        controller:open(parent)
        local mainFlow = controller.gui.mainFlow
        controller:close()
        assert.is_nil(rawget(controller, "gui"))
        assert.is_nil(parent.children[1])
        assert.is_false(mainFlow.valid)
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        controller:close()
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(controller:getGuiUpcalls(), appTestbench.appResources)
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
        assert.are.equals(controller.gui.mainFlow, parent.children[1])
        assert.is_false(controller.gui.mainFlow.indirect.visible)
        assert.is_false(controller.gui.normalCheckbox.rawElement.state)
    end)

    describe(":setFilterNormal()", function()
        it("-- no GUI", function()
            controller:setFilterNormal(1)
            assert.is_true(params.filterNormal)
        end)

        it("-- with GUI", function()
            controller:open(parent)
            controller:setFilterNormal(2)
            assert.is_true(params.filterNormal)
            assert.is_true(controller.gui.normalCheckbox.rawElement.state)
            assert.is_true(controller.gui.mainFlow.indirect.visible)
        end)
    end)

    describe(":setFilterRecursive()", function()
        it("-- no GUI", function()
            controller:setFilterRecursive(1)
            assert.is_true(params.filterRecursive)
        end)

        it("-- with GUI", function()
            controller:open(parent)
            controller:setFilterRecursive(2)
            assert.is_true(params.filterRecursive)
            assert.is_true(controller.gui.recursiveCheckbox.rawElement.state)
            assert.is_true(controller.gui.mainFlow.indirect.visible)
        end)
    end)

    describe(":setIndirectThreshold()", function()
        it("-- no GUI", function()
            controller:setIndirectThreshold(100)
            assert.are.equals(params.indirectThreshold, 100)
        end)

        it("-- with GUI", function()
            controller:setFilterNormal(true)
            controller:open(parent)
            local indirectCheckbox = controller.gui.indirectCheckbox.rawElement
            local indirectField = controller.gui.indirectField.rawElement

            controller:setIndirectThreshold(100)
            assert.are.equals(tonumber(indirectField.text), 100)
            assert.is_true(indirectField.enabled)
            assert.is_true(indirectCheckbox.state)

            controller:setIndirectThreshold(nil)
            assert.is_false(indirectField.enabled)
            assert.is_false(indirectCheckbox.state)
        end)
    end)

    describe("-- gui", function()
        before_each(function()
            controller:open(parent)
        end)

        it("IndirectCheckbox", function()
            local indirectCheckbox = controller.gui.indirectCheckbox.rawElement
            indirectCheckbox.state = false
            GuiElement.on_gui_checked_state_changed{
                element = indirectCheckbox,
                player_index = indirectCheckbox.player_index,
            }
            assert.is_nil(rawget(params, "indirectThreshold"))

            local indirectField = controller.gui.indirectField.rawElement
            indirectField.text = ""
            indirectCheckbox.state = true
            GuiElement.on_gui_checked_state_changed{
                element = indirectCheckbox,
                player_index = indirectCheckbox.player_index,
            }
            assert.are.equals(params.indirectThreshold, 64)

            indirectField.text = "33"
            GuiElement.on_gui_checked_state_changed{
                element = indirectCheckbox,
                player_index = indirectCheckbox.player_index,
            }
            assert.are.equals(params.indirectThreshold, 33)
        end)

        it("IndirectField", function()
            local indirectField = controller.gui.indirectField.rawElement
            indirectField.text = "10"
            GuiElement.on_gui_text_changed{
                element = indirectField,
                player_index = indirectField.player_index,
            }
            assert.are.equals(params.indirectThreshold, 10)
        end)

        it("NormalCheckbox", function()
            local normalCheckbox = controller.gui.normalCheckbox.rawElement
            normalCheckbox.state = true
            GuiElement.on_gui_checked_state_changed{
                element = normalCheckbox,
                player_index = normalCheckbox.player_index,
            }
            assert.is_true(params.filterNormal)
        end)

        it("RecursiveCheckbox", function()
            local recursiveCheckbox = controller.gui.recursiveCheckbox.rawElement
            recursiveCheckbox.state = true
            GuiElement.on_gui_checked_state_changed{
                element = recursiveCheckbox,
                player_index = recursiveCheckbox.player_index,
            }
            assert.is_true(params.filterRecursive)
        end)
    end)
end)
