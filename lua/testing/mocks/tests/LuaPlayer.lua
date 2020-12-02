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

local LuaPlayer = require("lua/testing/mocks/LuaPlayer")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaPlayer", function()
    local indices = {}
    local checkIndex = function(player)
        local index = player.index
        assert.is_nil(indices[index])
        indices[index] = true
    end

    local force = {}

    describe(".make()", function()
        it("-- valid", function()
            local object = LuaPlayer.make{
                force = force,
            }
            local data = MockObject.getData(object)
            assert.are.equals(MockObject.getData(data.cursor_stack).slot, data.cursorSlot)
            assert.are.equals(data.force, force)
            assert.is_not_nil(data.gui)
            checkIndex(object)
        end)

        it("-- invalid: no force", function()
            assert.error(function()
                LuaPlayer.make{}
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = LuaPlayer.make{
                force = force,
            }
        end)

        it(":clear_cursor()", function()
            local data = MockObject.getData(object)
            data.cursorSlot:setStack{name = "coal", count = 1}
            local stack = data.cursor_stack
            assert.is_true(stack.valid_for_read)

            object.clear_cursor()
            assert.is_false(stack.valid_for_read)
        end)

        it(":cursor_stack", function()
            assert.are.equals(MockObject.getData(object).cursor_stack, object.cursor_stack)
        end)

        describe(":force", function()
            it("-- read", function()
                assert.are.equals(object.force, force)
            end)

            it("-- write", function()
                assert.error(function()
                    object.force = "denied"
                end)
            end)
        end)

        it(":gui", function()
            assert.are.equals(MockObject.getData(object).gui, object.gui)
        end)

        describe(":index", function()
            it("-- read", function()
                assert.are.equals(object.index, MockObject.getData(object).index)
                assert.are.equals(type(object.index), "number")
            end)

            it("-- write", function()
                assert.error(function()
                    object.index = "denied"
                end)
            end)
        end)
    end)
end)
