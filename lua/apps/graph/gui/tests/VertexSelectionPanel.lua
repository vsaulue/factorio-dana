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
local GuiElement = require("lua/gui/GuiElement")
local RendererSelection = require("lua/renderers/RendererSelection")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local VertexSelectionPanel = require("lua/apps/graph/gui/VertexSelectionPanel")

describe("VertexSelectionPanel + GUI", function()
    local appTestbench
    local fakeSelectionWindow
    local selection
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

        fakeSelectionWindow = AutoLoaded.new{
            selectPanel = function() end,
        }

        selection = RendererSelection.new()
        selection.nodes.hyperVertex = {
            [{index = appTestbench.prototypes.intermediates.fluid.water}] = true,
        }

        parent = appTestbench.player.gui.screen
    end)

    local controller
    before_each(function()
        GuiElement.on_init()
        parent.clear()

        controller = VertexSelectionPanel.new{
            rawPlayer = appTestbench.player,
            selectionWindow = fakeSelectionWindow,
        }
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
                    VertexSelectionPanel.setmetatable(objects.controller)
                end,
            }
        end

        it("-- no GUI", function()
            runTest()
        end)

        it("-- with GUI", function()
            controller.elements = selection.nodes.hyperVertex
            controller:open(parent)
            runTest()
        end)
    end)

    it(":updateElements()", function()
        controller:open(parent)
        controller:updateElements(selection)
        assert.are.equals(controller.gui.mainFlow.content.children[1].children[2].sprite, "fluid/water")
    end)
end)
