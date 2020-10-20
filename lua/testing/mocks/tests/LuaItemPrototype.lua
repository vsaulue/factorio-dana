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

local LuaItemPrototype = require("lua/testing/mocks/LuaItemPrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaItemPrototype", function()
    describe(".make()", function()
        it("--valid", function()
            local object = LuaItemPrototype.make{
                type = "item",
                name = "some-ore",
            }
            assert.are.equals(getmetatable(object), LuaItemPrototype.Metatable)
        end)

        it("--invalid type", function()
            assert.error(function()
                object = LuaItemPrototype.make{
                    type = "nope",
                    name = "some-ore"
                }
            end)
        end)
    end)

    it("-- parent properties", function()
        local object = LuaItemPrototype.make{
            type = "item",
            name = "some-ore"
        }
        assert.are.same(object.localised_name, {"item-name.some-ore"})
    end)

    describe(":burnt_result", function()
        local object
        before_each(function()
            object = LuaItemPrototype.make{
                type = "item",
                name = "wood",
                burnt_result = "ash",
            }
        end)

        it("-- make", function()
            assert.are.equals(MockObject.getData(object).burnt_result, "ash")
        end)

        it("-- read", function()
            assert.are.equals(object.burnt_result, "ash")
        end)

        it("-- write", function()
            assert.error(function()
                object.burnt_result = "denied"
            end)
        end)
    end)
end)
