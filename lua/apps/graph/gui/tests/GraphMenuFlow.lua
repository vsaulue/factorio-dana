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
local AutoLoaded = require("lua/testing/AutoLoaded")
local Force = require("lua/model/Force")
local GraphAppInterface = require("lua/apps/graph/GraphAppInterface")
local GraphMenuFlow = require("lua/apps/graph/gui/GraphMenuFlow")
local GuiElement = require("lua/gui/GuiElement")
local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("GraphMenuFlow", function()
    local appInterface
    local factorio
    local surface
    local player
    local prototypes
    local force
    setup(function()
        appInterface = AutoLoaded.new{
            newQuery = function() end,
            viewGraphCenter = function() end,
            viewLegend = function() end,
        }
        GraphAppInterface.check(appInterface)

        factorio = MockFactorio.make{
            rawData = {},
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
    local parent
    local controller
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
        parent = LuaGuiElement.make({
            type = "flow",
            direction = "horizontal",
        }, player.index)
        controller = GraphMenuFlow.new{
            appInterface = appInterface,
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
                },
                metatableSetter = function(objects)
                    AppResources.setmetatable(objects.appResources)
                    PrototypeDatabase.setmetatable(objects.prototypes)
                    Force.setmetatable(objects.force)
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
        assert.are.equals(GuiElement.count(player.index), 0)
    end)

    describe("-- GUI:", function()
        before_each(function()
            controller:open(parent)
        end)

        it("NewQuery", function()
            stub(appInterface, "newQuery")
            GuiElement.on_gui_click{
                element = controller.gui.newQueryButton.rawElement,
                player_index = player.index,
            }
            assert.stub(appInterface.newQuery).was.called_with(appInterface)
        end)

        it("ViewGraphButton", function()
            stub(appInterface, "viewGraphCenter")
            GuiElement.on_gui_click{
                element = controller.gui.viewGraphButton.rawElement,
                player_index = player.index,
            }
            assert.stub(appInterface.viewGraphCenter).was.called_with(appInterface)
        end)

        it("ViewLegend", function()
            stub(appInterface, "viewLegend")
            GuiElement.on_gui_click{
                element = controller.gui.viewLegendButton.rawElement,
                player_index = player.index,
            }
            assert.stub(appInterface.viewLegend).was.called_with(appInterface)
        end)
    end)
end)
