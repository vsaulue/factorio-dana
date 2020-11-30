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
local GuiElement = require("lua/gui/GuiElement")
local ModGuiButton = require("lua/controller/ModGuiButton")
local PlayerCtrlInterface = require("lua/controller/PlayerCtrlInterface")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ModGuiButton + GUI", function()
    local appTestbench
    local parent
    local playerCtrlInterface
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {},
        }
        appTestbench:setup()

        parent = appTestbench.player.gui.left

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

        controller = ModGuiButton.new{
            playerCtrlInterface = playerCtrlInterface,
        }
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = controller,
                metatableSetter = ModGuiButton.setmetatable,
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
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        assert.is_nil(parent.children[1])
        assert.is_nil(rawget(controller, "gui"))
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(playerCtrlInterface, controller:getGuiUpcalls())
    end)

    describe(":gui:isValid()", function()
        controller:open(parent)
        local gui = controller.gui
        assert.is_true(gui:isValid())
        controller:close()
        assert.is_false(gui:isValid())
    end)

    it(":open()", function()
        controller:open(parent)
        assert.are.equals(controller.gui.button.rawElement, parent.children[1])
    end)

    it("-- GUI: OpenGuiButton", function()
        controller:open(parent)
        stub(playerCtrlInterface, "show")
        GuiElement.on_gui_click{
            element = controller.gui.button.rawElement,
            player_index = appTestbench.player.index,
        }
        assert.stub(playerCtrlInterface.show).was.called_with(match.ref(playerCtrlInterface))
    end)
end)
