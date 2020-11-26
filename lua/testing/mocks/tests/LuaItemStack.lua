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

local ItemSlot = require("lua/testing/mocks/ItemSlot")
local LuaItemStack = require("lua/testing/mocks/LuaItemStack")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaItemStack", function()
    local slot
    local stack
    before_each(function()
        slot = ItemSlot.new()
        stack = LuaItemStack.make{
            slot = slot,
        }
    end)

    local setValidSlot = function()
        slot:setStack{
            name = "coal",
            count = 49,
        }
    end

    it(".make()", function()
        local data = MockObject.getData(stack)
        assert.are.equals(slot, data.slot)
    end)

    describe(":count", function()
        it("-- read: valid", function()
            setValidSlot()
            assert.are.equals(stack.count, 49)
        end)

        it("-- read: invalid", function()
            assert.error(function()
                local _ = stack.count
            end)
        end)

        it("-- write: valid", function()
            setValidSlot()
            stack.count = 3
            assert.are.equals(slot.count, 3)
        end)

        it("-- write: invalid", function()
            assert.error(function()
                stack.count = 3
            end)
        end)
    end)

    describe(":name", function()
        it("-- valid", function()
            setValidSlot()
            assert.are.equals(stack.name, "coal")
        end)

        it("--invalid", function()
            assert.error(function()
                local _ = stack.name
            end)
        end)
    end)

    describe(":set_stack()", function()
        it("-- valid: nil", function()
            setValidSlot()
            stack.set_stack()
            assert.is_nil(slot.name)
        end)

        it("-- valid: other empty stack", function()
            local slot2 = ItemSlot.new()
            local stack2 = LuaItemStack.make{
                slot = slot2,
            }
            setValidSlot()
            stack.set_stack(stack2)
            assert.is_nil(slot.name)
        end)

        it("-- valid: other stack", function()
            local slot2 = ItemSlot.new()
            local stack2 = LuaItemStack.make{
                slot = slot2,
            }
            setValidSlot()
            stack2.set_stack(stack)
            assert.are.equals(slot2.name, "coal")
        end)

        it("-- valid: SimpleItemStack", function()
            stack.set_stack({name = "iron-ore"})
            assert.are.equals(slot.name, "iron-ore")
            assert.are.equals(slot.count, 1)
        end)

        it("-- invalid: 0", function()
            assert.error(function()
                stack.set_stack({name = "foobar", count = 0})
            end)
        end)
    end)
end)