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

local AbstractQueryEditor = require("lua/apps/query/step/editor/AbstractQueryEditor")
local AppTestbench = require("lua/testing/AppTestbench")
local AutoLoaded = require("lua/testing/AutoLoaded")
local GuiElement = require("lua/gui/GuiElement")
local HowToMakeEditor = require("lua/apps/query/step/editor/HowToMakeEditor")
local HowToMakeQuery = require("lua/query/HowToMakeQuery")
local MinDistEditor = require("lua/apps/query/params/MinDistEditor")
local QueryAppInterface = require("lua/apps/query/QueryAppInterface")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local UsagesOfQuery = require("lua/query/UsagesOfQuery")

describe("HowToMakeEditor + Abstract + GUI", function()
    local appInterface
    local appTestbench
    local items
    local parent
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

        items = appTestbench.prototypes.intermediates.item

        parent = appTestbench.player.gui.screen
    end)

    before_each(function()
        parent.clear()
        GuiElement.on_init()
    end)

    describe(".make()", function()
        local cArgs
        before_each(function()
            cArgs = {
                appInterface = appInterface,
                query = HowToMakeQuery.new(),
            }
        end)

        it("-- valid", function()
            local controller = HowToMakeEditor.new(cArgs)
            assert.is_not_nil(controller.paramsEditor)
            assert.is_false(controller.paramsEditor.isForward)
        end)

        it("-- wrong query", function()
            cArgs.query = UsagesOfQuery.new()
            assert.error(function()
                HowToMakeEditor.new(cArgs)
            end)
        end)
    end)

    describe("", function()
        local controller
        before_each(function()
            local query = HowToMakeQuery.new()
            query.destParams.intermediateSet[items.wood] = true
            query.destParams.maxDepth = 8

            controller = HowToMakeEditor.new{
                appInterface = appInterface,
                query = query,
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
                        AbstractQueryEditor.Factory:restoreMetatable(objects.controller)
                    end,
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
            local wood = items.wood
            controller:open(parent)
            controller:close()
            assert.is_nil(rawget(controller, "gui"))
            assert.is_nil(rawget(controller.paramsEditor, "gui"))
            assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
            assert.is_nil(parent.children[1])
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
            local wood = items.wood
            assert.is_not_nil(rawget(controller.paramsEditor.setEditor.gui.selectedIntermediates.reverse, wood))
        end)

        describe(":setParamsEditor()", function()
            local newEditor
            before_each(function()
                newEditor = MinDistEditor.new{
                    appResources = appTestbench.appResources,
                    isForward = false,
                    params = controller.query.destParams,
                }
            end)

            it("-- no GUI", function()
                controller:setParamsEditor(newEditor)
                assert.are.equals(controller.paramsEditor, newEditor)
                assert.is_nil(rawget(controller.paramsEditor, "gui"))
            end)

            it("-- with GUI", function()
                local oldEditor = controller.paramsEditor
                controller:open(parent)
                controller:setParamsEditor(newEditor)
                assert.is_nil(rawget(oldEditor, "gui"))
                assert.are.equals(controller.paramsEditor, newEditor)
                assert.is_not_nil(controller.paramsEditor.gui)
            end)
        end)

        describe("-- GUI:", function()
            before_each(function()
                controller:open(parent)
            end)

            it("BackButton", function()
                stub(appInterface, "popStepWindow")
                GuiElement.on_gui_click{
                    element = controller.gui.backButton.rawElement,
                    player_index = appTestbench.player.index,
                }
                assert.stub(appInterface.popStepWindow).was.called()
            end)

            it("DrawButton", function()
                stub(appInterface, "runQueryAndDraw")
                GuiElement.on_gui_click{
                    element = controller.gui.drawButton.rawElement,
                    player_index = appTestbench.player.index,
                }
                assert.stub(appInterface.runQueryAndDraw).was.called()
            end)
        end)
    end)
end)
