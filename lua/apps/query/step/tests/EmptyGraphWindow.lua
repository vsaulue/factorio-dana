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
local AutoLoaded = require("lua/testing/AutoLoaded")
local EmptyGraphWindow = require("lua/apps/query/step/EmptyGraphWindow")
local Force = require("lua/model/Force")
local GuiElement = require("lua/gui/GuiElement")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local QueryAppInterface = require("lua/apps/query/QueryAppInterface")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("EmptyGraphWindow", function()
    local factorio
    local surface
    local player
    local parent
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
        parent = player.gui.center
        surface = factorio.game.create_surface("dana", {})
        factorio:setup()

        prototypes = PrototypeDatabase.new(factorio.game)
        force = Force.new{
            prototypes = prototypes,
            rawForce = factorio.game.forces.player,
        }
    end)

    local appResources
    local appInterface
    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        appResources = AppResources.new{
            force = force,
            menuFlow = {},
            rawPlayer = player,
            surface = surface,
            upcalls = {},
        }
        appInterface = AutoLoaded.new{
            appResources = appResources,
            pushStepWindow = function() end,
            popStepWindow = function() end,
            runQueryAndDraw = function() end,
        }
        QueryAppInterface.check(appInterface)

        controller = EmptyGraphWindow.new{
            appInterface = appInterface,
        }
    end)

    it(".new()", function()
        assert.are.equals(controller.stepName, "emptyGraph")
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
                    PrototypeDatabase.setmetatable(objects.prototypes)
                    Force.setmetatable(objects.force)
                    AppResources.setmetatable(objects.appResources)
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
        assert.are.equals(GuiElement.count(player.index), 0)
        controller:close()
    end)

    it(":open()", function()
        controller:open(parent)
        assert.are.equals(parent.children[1], controller.gui.frame)
    end)

    it("-- GUI: BackButton", function()
        controller:open(parent)
        stub(appInterface, "popStepWindow")
        GuiElement.on_gui_click{
            element = controller.gui.backButton.rawElement,
            player_index = player.index,
        }
        assert.stub(appInterface.popStepWindow).was.called_with(appInterface)
    end)
end)