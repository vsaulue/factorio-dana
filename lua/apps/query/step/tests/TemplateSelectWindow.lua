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

local AbstractStepWindow = require("lua/apps/query/step/AbstractStepWindow")
local AppResources = require("lua/apps/AppResources")
local AppTestbench = require("lua/testing/AppTestbench")
local AutoLoaded = require("lua/testing/AutoLoaded")
local GuiElement = require("lua/gui/GuiElement")
local QueryAppInterface = require("lua/apps/query/QueryAppInterface")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TemplateSelectWindow = require("lua/apps/query/step/TemplateSelectWindow")

local match = require("luassert.match")
assert:register("matcher", "isFullGraphQuery", function()
    return function(value)
        return (value.queryType == "FullGraphQuery")
    end
end)
assert:register("matcher", "isQueryEditor", function(state, args)
    return function(value)
        local queryName = args[1]
        return (value.stepName == "queryEditor") and (value.query.queryType == queryName)
    end
end)

describe("TemplateSelectWindow", function()
    local parent
    local force
    local appTestbench
    local appInterface
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {
                fluid = {
                    steam = {type = "fluid", name = "steam"},
                    water = {type = "fluid", name = "water"},
                },
                item = {
                    coal = {type = "item", name = "coal"},
                    wood = {type = "item", name = "wood"},
                },
            },
        }
        appTestbench:setup()

        appInterface = AutoLoaded.new{
            appResources = appTestbench.appResources,
            pushStepWindow = function() end,
            popStepWindow = function() end,
            runQueryAndDraw = function() end,
        }
        QueryAppInterface.check(appInterface)

        parent = appTestbench.player.gui.screen
    end)

    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        controller = TemplateSelectWindow.new{
            appInterface = appInterface,
        }
    end)

    it(".new()", function()
        assert.are.equals(controller.stepName, "templateSelect")
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
                    AbstractStepWindow.Factory:restoreMetatable(objects.controller)
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
        controller:close()
        assert.is_nil(parent.children[1])
        assert.is_nil(rawget(controller, "gui"))
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        controller:close()
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
        assert.are.equals(parent.children[1], controller.gui.frame)
    end)

    describe("-- GUI", function()
        before_each(function()
            controller:open(parent)
        end)

        it("-- FullGraphButton", function()
            stub(appInterface, "runQueryAndDraw")
            GuiElement.on_gui_click{
                element = controller.gui.fullGraphButton.rawElement,
                player_index = appTestbench.player.index,
            }
            assert.stub(appInterface.runQueryAndDraw).was.called_with(match.ref(appInterface), match.isFullGraphQuery())
        end)

        it("-- TemplateSelectWindow: UsagesOf", function()
            stub(appInterface, "pushStepWindow")
            GuiElement.on_gui_click{
                element = controller.gui.templateButtons.UsagesOf.rawElement,
                player_index = appTestbench.player.index,
            }
            assert.stub(appInterface.pushStepWindow).was.called_with(match.ref(appInterface), match.isQueryEditor("UsagesOfQuery"))
        end)

        it("-- TemplateSelectWindow: HowToMake", function()
            stub(appInterface, "pushStepWindow")
            GuiElement.on_gui_click{
                element = controller.gui.templateButtons.HowToMake.rawElement,
                player_index = appTestbench.player.index,
            }
            assert.stub(appInterface.pushStepWindow).was.called_with(match.ref(appInterface), match.isQueryEditor("HowToMakeQuery"))
        end)
    end)
end)
