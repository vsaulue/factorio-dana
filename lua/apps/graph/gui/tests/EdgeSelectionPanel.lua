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
local AutoLoaded = require("lua/testing/AutoLoaded")
local EdgeSelectionPanel = require("lua/apps/graph/gui/EdgeSelectionPanel")
local GuiElement = require("lua/gui/GuiElement")
local RendererSelection = require("lua/renderers/RendererSelection")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("EdgeSelectionPanel + Abstract + GUI", function()
    local appTestbench
    local selection
    local fakeSelectionWindow
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

        selection = RendererSelection.new()
        selection.nodes.hyperEdge = {
            [{index = appTestbench.prototypes.transforms.boiler.myBoiler}] = true,
        }

        fakeSelectionWindow = AutoLoaded.new{
            appResources = appTestbench.appResources,
            selectPanel = function() end,
        }

        parent = appTestbench.player.gui.screen
    end)

    local controller
    before_each(function()
        GuiElement.on_init()
        parent.clear()

        controller = EdgeSelectionPanel.new{
            rawPlayer = appTestbench.player,
            selectionWindow = fakeSelectionWindow,
        }
    end)

    it(".new()", function()
        assert.is_not_nil(controller.hasElements)
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
                    EdgeSelectionPanel.setmetatable(objects.controller)
                end,
            }
        end

        it("-- no GUI", function()
            runTest()
        end)

        it("-- with GUI", function()
            controller.elements = selection.nodes.hyperEdge
            controller:open(parent)
            runTest()
        end)
    end)

    it(":close()", function()
        controller.elements = selection.nodes.hyperEdge
        controller:open(parent)
        controller:close()
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        assert.is_nil(parent.children[1])
        assert.is_nil(rawget(controller, "gui"))
        controller:close()
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(appTestbench.appResources, controller:getGuiUpcalls())
    end)

    it(":gui:isValid()", function()
        controller:open(parent)
        local gui = controller.gui
        assert.is_true(gui:isValid())
        controller:close()
        assert.is_false(gui:isValid())
    end)

    it(":hasElements()", function()
        assert.is_falsy(controller:hasElements())
        controller.elements = {}
        assert.is_falsy(controller:hasElements())
        controller.elements = selection.nodes.hyperEdge
        assert.is_truthy(controller:hasElements())
    end)

    it(":open()", function()
        controller.elements = selection.nodes.hyperEdge
        controller:open(parent)
        assert.are.equals(parent.children[1], controller.gui.mainFlow)
        assert.is_not_nil(controller.gui.mainFlow.content.children[1])
    end)

    describe(":setExpanded", function()
        it("--no GUI", function()
            controller:setExpanded(true)
            assert.is_true(controller.expanded)
        end)

        it("-- with GUI", function()
            controller:open(parent)
            controller:setExpanded(true)
            assert.is_true(controller.gui.mainFlow.content.visible)
        end)
    end)

    describe(":updateElements()", function()
        it("-- no GUI", function()
            controller:updateElements(selection)
            assert.are.equals(controller.elements, selection.nodes.hyperEdge)
        end)

        it("-- with GUI", function()
            controller:open(parent)
            controller:updateElements(selection)
            assert.are.equals(controller.gui.mainFlow.content.children[1].children[2].sprite, "entity/myBoiler")
        end)
    end)

    it("-- GUI: SelectionCategoryLabel", function()
        controller:open(parent)
        stub(fakeSelectionWindow, "selectPanel")
        GuiElement.on_gui_click{
            element = controller.gui.titleLabel.rawElement,
            player_index = appTestbench.player.index,
        }
        assert.stub(fakeSelectionWindow.selectPanel).was.called_with(match.ref(fakeSelectionWindow), match.ref(controller))
    end)
end)
