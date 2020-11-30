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

local AutoLoaded = require("lua/testing/AutoLoaded")
local GuiElement = require("lua/gui/GuiElement")
local MenuWindow = require("lua/controller/MenuWindow")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PlayerCtrlInterface = require("lua/controller/PlayerCtrlInterface")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("MenuWindow", function()
    local factorio
    local player
    local playerCtrlInterface
    setup(function()
        factorio = MockFactorio.make{
            rawData = {},
        }
        player = factorio:createPlayer{
            forceName = "player",
        }
        parent = player.gui.screen
        factorio:setup()

        playerCtrlInterface = AutoLoaded.new{
            hide = function() end,
            notifyGuiCorrupted = function() end,
            show = function() end,
        }
        PlayerCtrlInterface.check(playerCtrlInterface)
    end)

    local controller
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        controller = MenuWindow.new{
            playerCtrlInterface = playerCtrlInterface,
        }
    end)

    it(".new()", function()
        assert.is_not_nil(controller.open)
        assert.are.equals(controller.playerCtrlInterface, playerCtrlInterface)
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = controller,
                metatableSetter = MenuWindow.setmetatable,
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

    describe(":close()", function()
        it("-- no appMenu", function()
            controller:open(parent)
            controller:close()
            assert.is_nil(rawget(controller, "gui"))
            assert.is_nil(parent.children[1])
            assert.are.equals(GuiElement.count(player.index), 0)
            controller:close()
        end)

        it("-- with appMenu", function()
            local appMenu = MenuWindow.new{
                playerCtrlInterface = playerCtrlInterface,
            }
            controller:setAppMenu(appMenu)

            controller:open(parent)
            controller:close()
            assert.is_nil(rawget(controller, "gui"))
            assert.is_nil(rawget(appMenu, "gui"))
            assert.is_nil(parent.children[1])
            assert.are.equals(GuiElement.count(player.index), 0)
            controller:close()
        end)
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(playerCtrlInterface, controller:getGuiUpcalls())
    end)

    it(":gui:isValid()", function()
        controller:open(parent)
        local gui = controller.gui
        assert.is_true(gui:isValid())
        controller:close()
        assert.is_false(gui:isValid())
    end)

    describe(":setMenuApp()", function()
        local appMenu
        before_each(function()
            appMenu = MenuWindow.new{
                playerCtrlInterface = playerCtrlInterface,
            }
        end)

        it("-- no gui", function()
            controller:setAppMenu(appMenu)
            assert.are.equals(controller.appMenu, appMenu)
            assert.is_nil(rawget(appMenu, "gui"))

            controller:setAppMenu(nil)
            assert.is_nil(rawget(controller, "appMenu"))
        end)

        it("-- gui", function()
            controller:open(parent)

            controller:setAppMenu(appMenu)
            assert.are.equals(appMenu.gui.frame, controller.gui.frame.appFlow.children[1])

            controller:setAppMenu(nil)
            assert.is_nil(rawget(appMenu, "gui"))
            assert.is_nil(controller.gui.frame.appFlow.children[1])
        end)
    end)

    it("-- GUI: HideButton", function()
        stub(playerCtrlInterface, "hide")
        controller:open(parent)

        GuiElement.on_gui_click{
            element = controller.gui.hideButton.rawElement,
            player_index = player.index,
        }
        assert.stub(playerCtrlInterface.hide).was.called_with(playerCtrlInterface, false)
    end)
end)
