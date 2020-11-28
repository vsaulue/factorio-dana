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
local MinDistEditor = require("lua/apps/query/params/MinDistEditor")
local MinDistParams = require("lua/query/params/MinDistParams")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("MinDistEditor & GUI", function()
    local appTestbench
    local parent
    setup(function()
        local rawData = {
            fluid = {
                steam = {type = "fluid", name = "steam"},
                water = {type = "fluid", name = "water"},
            },
            item = {
                coal = {type = "item", name = "coal"},
                wood = {type = "item", name = "wood"},
            },
        }
        for i=1,5 do
            local itemName = "item" .. i
            rawData.item[itemName] = {type = "item", name = itemName}
        end

        appTestbench = AppTestbench.make{
            rawData = rawData,
        }
        appTestbench:setup()

        parent = appTestbench.player.gui.center
    end)

    local params
    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        params = MinDistParams.new{
            allowOtherIntermediates = true,
            intermediateSet = {
                [appTestbench.prototypes.intermediates.item.wood] = true,
            },
            maxDepth = 5,
        }
        controller = MinDistEditor.new{
            appResources = appTestbench.appResources,
            isForward = false,
            params = params,
        }
    end)

    it(".new()", function()
        assert.is_not_nil(controller.setEditor)
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
                    MinDistEditor.setmetatable(objects.controller)
                    MinDistParams.setmetatable(objects.params)
                end,
            }
        end

        it("-- no gui", function()
            runTest()
        end)

        it("-- gui", function()
            controller:open(parent)
            runTest()
        end)
    end)

    it(":close()", function()
        controller:open(parent)
        local mainFlow = controller.gui.mainFlow
        controller:close()
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        assert.is_false(mainFlow.valid)
        assert.is_nil(rawget(controller, "gui"))
        assert.is_nil(parent.children[1])
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

    it(":open()", function()
        controller:open(parent)
        assert.are.equals(parent.children[1], controller.gui.mainFlow)
    end)

    describe(":setAllowOther()", function()
        it("-- no gui", function()
            controller:setAllowOther(false)
            assert.is_false(params.allowOtherIntermediates)
        end)

        it("-- with gui", function()
            controller:open(parent)
            controller:setAllowOther(false)
            assert.is_false(params.allowOtherIntermediates)
            assert.is_false(controller.gui.allowOtherCheckbox.rawElement.state)
        end)
    end)

    describe(":setDepth()", function()
        it("-- no gui", function()
            controller:setDepth(17)
            assert.are.equals(params.maxDepth, 17)
        end)

        it("-- with gui", function()
            controller:open(parent)
            local depthCheckbox = controller.gui.depthCheckbox.rawElement
            local depthField = controller.gui.depthField.rawElement

            controller:setDepth(nil)
            assert.is_nil(rawget(params, "maxDepth"))
            assert.is_false(depthCheckbox.state)
            assert.is_false(depthField.enabled)

            controller:setDepth(4)
            assert.are.equals(params.maxDepth, 4)
            assert.is_true(depthCheckbox.state)
            assert.is_true(depthField.enabled)
            assert.are.equals(depthField.text, "4")
        end)
    end)

    describe("-- gui", function()
        before_each(function()
            controller:open(parent)
        end)

        it("AllowOtherCheckbox", function()
            local allowCheckbox = controller.gui.allowOtherCheckbox.rawElement
            allowCheckbox.state = false
            GuiElement.on_gui_checked_state_changed{
                element = allowCheckbox,
                player_index = allowCheckbox.player_index,
            }
            assert.is_false(params.allowOtherIntermediates)
        end)

        it("DepthCheckbox", function()
            local depthCheckbox = controller.gui.depthCheckbox.rawElement
            depthCheckbox.state = false
            GuiElement.on_gui_checked_state_changed{
                element = depthCheckbox,
                player_index = depthCheckbox.player_index,
            }
            assert.is_nil(rawget(params, "maxDepth"))

            local depthField = controller.gui.depthField.rawElement
            depthField.text = ""
            depthCheckbox.state = true
            GuiElement.on_gui_checked_state_changed{
                element = depthCheckbox,
                player_index = depthCheckbox.player_index,
            }
            assert.are.equals(params.maxDepth, 1)

            depthField.text = "5"
            GuiElement.on_gui_checked_state_changed{
                element = depthCheckbox,
                player_index = depthCheckbox.player_index,
            }
            assert.are.equals(params.maxDepth, 5)
        end)

        it("DepthField", function()
            local depthField = controller.gui.depthField.rawElement
            depthField.text = "10"
            GuiElement.on_gui_text_changed{
                element = depthField,
                player_index = depthField.player_index,
            }
            assert.are.equals(params.maxDepth, 10)
        end)
    end)
end)
