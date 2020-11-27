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
local GraphAppInterface = require("lua/apps/graph/GraphAppInterface")
local GraphMenuFlow = require("lua/apps/graph/gui/GraphMenuFlow")
local GuiElement = require("lua/gui/GuiElement")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("GraphMenuFlow", function()
    local appInterface
    local appTestbench
    local parent
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {},
        }
        appTestbench:setup()

        appInterface = AutoLoaded.new{
            appResources = appTestbench.appResources,
            newQuery = function() end,
            viewGraphCenter = function() end,
            viewLegend = function() end,
        }
        GraphAppInterface.check(appInterface)

        parent = appTestbench.player.gui.center
    end)

    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        controller = GraphMenuFlow.new{
            appInterface = appInterface,
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
                    GraphMenuFlow.setmetatable(objects.controller)
                end,
            }
        end

        it("-- no GUI", function()
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

    describe("-- GUI:", function()
        before_each(function()
            controller:open(parent)
        end)

        it("NewQuery", function()
            stub(appInterface, "newQuery")
            GuiElement.on_gui_click{
                element = controller.gui.newQueryButton.rawElement,
                player_index = appTestbench.player.index,
            }
            assert.stub(appInterface.newQuery).was.called_with(match.ref(appInterface))
        end)

        it("ViewGraphButton", function()
            stub(appInterface, "viewGraphCenter")
            GuiElement.on_gui_click{
                element = controller.gui.viewGraphButton.rawElement,
                player_index = appTestbench.player.index,
            }
            assert.stub(appInterface.viewGraphCenter).was.called_with(match.ref(appInterface))
        end)

        it("ViewLegend", function()
            stub(appInterface, "viewLegend")
            GuiElement.on_gui_click{
                element = controller.gui.viewLegendButton.rawElement,
                player_index = appTestbench.player.index,
            }
            assert.stub(appInterface.viewLegend).was.called_with(match.ref(appInterface))
        end)
    end)
end)
