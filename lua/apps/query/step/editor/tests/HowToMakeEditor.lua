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
local AppResources = require("lua/apps/AppResources")
local Force = require("lua/model/Force")
local GuiElement = require("lua/gui/GuiElement")
local HowToMakeEditor = require("lua/apps/query/step/editor/HowToMakeEditor")
local HowToMakeQuery = require("lua/query/HowToMakeQuery")
local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")
local MinDistEditor = require("lua/apps/query/params/MinDistEditor")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PrototypeDatabase = require("lua/model.PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local UsagesOfQuery = require("lua/query/UsagesOfQuery")

describe("HowToMakeEditor + Abstract + GUI", function()
    local factorio
    local surface
    local player
    local prototypes
    local force
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
        factorio = MockFactorio.make{
            rawData = rawData,
        }
        player = factorio:createPlayer{
            forceName = "player",
        }
        surface = factorio.game.create_surface("dana", {})
        factorio:setup()

        prototypes = PrototypeDatabase.new(factorio.game)
        force = Force.new{
            prototypes = prototypes,
            rawForce = factorio.game.forces.player,
        }
    end)

    local appResources
    local app
    before_each(function()
        GuiElement.on_init()
        appResources = AppResources.new{
            force = force,
            menuFlow = LuaGuiElement.make({
                type = "flow",
                direction = "horizontal",
            }, player.index),
            rawPlayer = player,
            surface = surface,
            upcalls = {},
        }
        app = {
            appResources = appResources,
        }
    end)

    describe(".make()", function()
        local cArgs
        before_each(function()
            cArgs = {
                app = app,
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
        local parent
        before_each(function()
            parent = LuaGuiElement.make({
                type = "flow",
                direction = "horizontal",
            }, player.index)

            local query = HowToMakeQuery.new()
            query.destParams.intermediateSet[prototypes.intermediates.item.wood] = true
            query.destParams.maxDepth = 8

            controller = HowToMakeEditor.new{
                app = app,
                query = query,
            }
        end)

        describe(".setmetatable()", function()
            local runTest = function()
                SaveLoadTester.run{
                    objects = {
                        appResources = appResources,
                        controller = controller,
                        force = force,
                        prototypes = prototypes,
                        query = controller.query,
                    },
                    metatableSetter = function(objects)
                        PrototypeDatabase.setmetatable(objects.prototypes)
                        Force.setmetatable(objects.force)
                        AppResources.setmetatable(objects.appResources)
                        HowToMakeQuery.setmetatable(objects.query)
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
            local wood = prototypes.intermediates.item.wood
            controller:open(parent)
            controller:close()
            assert.is_nil(rawget(controller, "gui"))
            assert.is_nil(rawget(controller.paramsEditor, "gui"))
            assert.are.equals(GuiElement.count(player.index), 0)
            assert.is_nil(parent.children[1])
            controller:close()
        end)

        it(":open()", function()
            controller:open(parent)
            local wood = prototypes.intermediates.item.wood
            assert.is_not_nil(rawget(controller.paramsEditor.setEditor.gui.selectedIntermediates.reverse, wood))
        end)

        describe(":setParamsEditor()", function()
            local newEditor
            before_each(function()
                newEditor = MinDistEditor.new{
                    appResources = controller.app.appResources,
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
                stub(app, "popStepWindow")
                GuiElement.on_gui_click{
                    element = controller.gui.backButton.rawElement,
                    player_index = player.index,
                }
                assert.stub(app.popStepWindow).was.called()
            end)

            it("DrawButton", function()
                stub(app, "runQueryAndDraw")
                GuiElement.on_gui_click{
                    element = controller.gui.drawButton.rawElement,
                    player_index = player.index,
                }
                assert.stub(app.runQueryAndDraw).was.called()
            end)
        end)
    end)
end)
