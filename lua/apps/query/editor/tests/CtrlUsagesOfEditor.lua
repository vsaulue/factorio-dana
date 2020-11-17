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
local Force = require("lua/model/Force")
local GuiElement = require("lua/gui/GuiElement")
local LuaGuiElement = require("lua/testing/mocks/LuaGuiElement")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local CtrlUsagesOfEditor = require("lua/apps/query/editor/CtrlUsagesOfEditor")
local UsagesOfQuery = require("lua/query/UsagesOfQuery")

describe("CtrlUsagesOfEditor", function()
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

    local app
    local appResources
    local controller
    local parent
    before_each(function()
        GuiElement.on_init()
        parent = LuaGuiElement.make({
            type = "flow",
            direction = "horizontal",
        }, player.index)
        appResources = AppResources.new{
            force = force,
            menuFlow = LuaGuiElement.make({
                type = "flow",
                direction = "horizontal",
            }, player.index),
            rawPlayer = player,
            surface = surface,
        }
        app = {
            appController = {
                appResources = appResources,
            }
        }
        controller = CtrlUsagesOfEditor.new{
            app = app,
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
                    UsagesOfQuery.setmetatable(objects.query)
                    CtrlUsagesOfEditor.setmetatable(objects.controller)
                end,
            }
        end

        it("-- no gui", function()
            controller:close()
            runTest()
        end)

        it("-- with gui", function()
            runTest()
        end)
    end)
end)
