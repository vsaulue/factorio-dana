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
local AbstractGui = require("lua/gui/AbstractGui")
local AbstractGuiController = require("lua/gui/AbstractGuiController")
local GuiUpcalls = require("lua/gui/GuiUpcalls")
local MetaUtils = require("lua/class/MetaUtils")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("AbstractGuiController", function()
    local GuiMetatable = {
        __index = {
            close = function(self)
                self.opened = false
            end,

            isValid = function(self)
                return self.opened
            end,
        },
    }
    MetaUtils.derive(AbstractGui.Metatable, GuiMetatable)

    local CtrlMetatable = {
        __index = {
            getGuiUpcalls = function(self)
                return self.upcalls
            end,

            makeGui = function(self, parent)
                local result = {
                    controller = self,
                    parent = parent,
                    opened = true,
                }
                return AbstractGui.new(result, GuiMetatable)
            end,
        },
    }
    MetaUtils.derive(AbstractGuiController.Metatable, CtrlMetatable)

    local upcalls
    setup(function()
        upcalls = AutoLoaded.new{
            notifyGuiCorrupted = function() end,
        }
        GuiUpcalls.checkMethods(upcalls)
    end)

    local object
    before_each(function()
        object = AbstractGuiController.new({
            upcalls = upcalls,
        }, CtrlMetatable)
    end)

    it(".new()", function()
        assert.is_nil(rawget(object, "gui"))
        assert.are.equals(CtrlMetatable.__index.makeGui, object.makeGui)
    end)

    describe(".setmetatable()", function()
        local guiSetter = function(object)
            setmetatable(object, GuiMetatable)
        end
        local ctrlSetter = function(object)
            AbstractGuiController.setmetatable(object, CtrlMetatable, guiSetter)
        end

        it("-- no gui", function()
            SaveLoadTester.run{
                objects = object,
                metatableSetter = ctrlSetter,
            }
        end)

        it("-- with gui", function()
            object:open{}
            SaveLoadTester.run{
                objects = object,
                metatableSetter = ctrlSetter,
            }
        end)
    end)

    describe("", function()
        local parent = {foo = "bar"}
        before_each(function()
            object:open(parent)
        end)

        it(":open()", function()
            assert.are.same(object.gui, {
                controller = object,
                parent = parent,
                opened = true,
            })
        end)

        it(":close()", function()
            local gui = object.gui
            object:close()
            assert.is_nil(rawget(object, "gui"))
            assert.is_false(gui.opened)
            object:close()
        end)

        it(":repair()", function()
            local gui = object.gui
            object:repair(parent)
            assert.are.equals(gui, object.gui)

            gui.opened = false
            object:repair(parent)
            assert.are_not.equals(gui, object.gui)
        end)

        describe(":sanityCheck()", function()
            before_each(function()
                stub(upcalls, "notifyGuiCorrupted")
            end)

            it("-- valid", function()
                local result = object.gui:sanityCheck()
                assert.is_true(result)
                assert.stub(upcalls.notifyGuiCorrupted).was_not_called()
            end)

            it("-- not valid", function()
            object.gui.opened = false
            local result = object.gui:sanityCheck()
            assert.is_false(result)
            assert.stub(upcalls.notifyGuiCorrupted).was.called_with(match.ref(upcalls))
            end)
        end)
    end)
end)
