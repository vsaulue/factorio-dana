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

local AppResources = require("lua/apps/AppResources")
local AppTestbench = require("lua/testing/AppTestbench")
local AutoLoaded = require("lua/testing/AutoLoaded")
local GuiElement = require("lua/gui/GuiElement")
local QueryAppInterface = require("lua/apps/query/QueryAppInterface")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local UsagesOfEditor = require("lua/apps/query/step/editor/UsagesOfEditor")
local UsagesOfQuery = require("lua/query/UsagesOfQuery")

describe("UsagesOfEditor", function()
    local appInterface
    local appTestbench
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

        parent = appTestbench.player.gui.center
    end)

    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        controller = UsagesOfEditor.new{
            appInterface = appInterface,
            query = UsagesOfQuery.new(),
        }
    end)

    it(".make()", function()
        assert.is_not_nil(controller.paramsEditor)
        assert.is_true(controller.paramsEditor.isForward)
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
                    UsagesOfEditor.setmetatable(objects.controller)
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
end)
