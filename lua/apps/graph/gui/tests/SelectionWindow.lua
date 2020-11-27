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

local AppTestbench = require("lua/testing/AppTestbench")
local GuiElement = require("lua/gui/GuiElement")
local RendererSelection = require("lua/renderers/RendererSelection")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local SelectionWindow = require("lua/apps/graph/gui/SelectionWindow")

describe("SelectionWindow", function()
    local appTestbench
    local fluids
    local boilers
    local parent
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {
                fluid = {
                    steam = {type = "fluid", name = "steam"},
                    water = {type = "fluid", name = "water"},
                },
                boiler = {
                    myBoiler = {
                        type = "boiler",
                        name = "myBoiler",
                        energy_source = {
                            type = "void",
                        },
                        fluid_box = {
                            production_type = "input-output",
                            filter = "water",
                        },
                        output_fluid_box = {
                            production_type = "output",
                            filter = "steam",
                        },
                    },
                },
            },
        }
        appTestbench:setup()

        fluids = appTestbench.prototypes.intermediates.fluid
        boilers = appTestbench.prototypes.transforms.boiler

        parent = appTestbench.player.gui.screen
    end)

    local controller
    before_each(function()
        GuiElement.on_init()
        parent.clear()

        controller = SelectionWindow.new{
            appResources = appTestbench.appResources,
            location = {50,50},
            maxHeight = 1024,
        }
    end)

    it(".new()", function()
        for i=1,4 do
            assert.is_not_nil(controller.panels[i].extractElements)
        end
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = {
                    appTestbench = appTestbench,
                    controller = controller,
                },
                metatableSetter = function(objects)
                    AppTestbench.setmetatable(objects.appTestbench)
                    SelectionWindow.setmetatable(objects.controller)
                end,
            }
        end

        it("--no GUI", function()
            controller:setSelection(RendererSelection.new())
            runTest()
        end)

        it("-- GUI", function()
            controller:open(parent)
            runTest()
        end)
    end)

    it(":close()", function()
        controller:open(parent)
        controller:close()
        assert.is_nil(parent.children[1])
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        assert.is_nil(rawget(controller, "gui"))
        for _,panel in ipairs(controller.panels) do
           assert.is_nil(rawget(panel, "gui"))
        end
    end)

    it(":getGuiUpcalls()", function()
        local upcalls = appTestbench.appResources
        assert.are.equals(upcalls, controller:getGuiUpcalls())
        assert.are.equals(upcalls, controller.panels[1]:getGuiUpcalls())
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
        assert.are.equals(controller.gui.frame, parent.children[1])
        for _,panel in ipairs(controller.panels) do
            assert.are.equals(controller.gui.frame, panel.gui.mainFlow.parent)
        end
    end)

    it(":selectPanel()", function()
        local rendererSelection = RendererSelection.new()
        rendererSelection.nodes.hyperEdge[{index = boilers.myBoiler}] = true
        rendererSelection.nodes.hyperVertex[{index = fluids.water}] = true
        controller:open(parent)
        controller:selectPanel(controller.panels[3])
        for index,panel in ipairs(controller.panels) do
            assert.are.equals(panel.expanded, (index == 3))
        end
    end)

    describe(":setSelection()", function()
        local rendererSelection
        before_each(function()
            controller:open(parent)
            rendererSelection = RendererSelection.new()
        end)
        it("-- empty selection", function()
            controller:setSelection(rendererSelection)
            controller:setSelection(rendererSelection)
            for _,panel in ipairs(controller.panels) do
                assert.is_false(panel.gui.mainFlow.visible)
                assert.is_not_nil(panel.elements)
            end
            assert.is_true(controller.gui.frame.noSelection.visible)
        end)

        it("-- non-empty selection", function()
            rendererSelection.nodes.hyperEdge[{index = boilers.myBoiler}] = true
            controller:setSelection(rendererSelection)
            for index,panel in ipairs(controller.panels) do
                assert.are.equals(panel.gui.mainFlow.visible, (index == 3))
                assert.are.equals(panel.expanded, (index == 3))
                assert.is_not_nil(panel.elements)
            end
            assert.is_false(controller.gui.frame.noSelection.visible)
        end)
    end)

    it("-- GUI: SelectToolButton", function()
        controller:open(parent)
        GuiElement.on_gui_click{
            element = controller.gui.selectToolButton.rawElement,
            player_index = appTestbench.player.index,
        }
        assert.are.equals(appTestbench.player.cursor_stack.name, "dana-select")
    end)
end)
