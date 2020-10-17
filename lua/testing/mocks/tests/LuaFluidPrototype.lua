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

local LuaFluidPrototype = require("lua/testing/mocks/LuaFluidPrototype")

describe("LuaFluidPrototype", function()
    describe(".make()", function()
        it("-- valid", function()
            local object = LuaFluidPrototype.make{
                type = "fluid",
                name = "vespene-gas",
            }
            assert.are.equals(getmetatable(object).className, "LuaFluidPrototype")
        end)

        it("-- wrong type", function()
            assert.error(function()
                LuaFluidPrototype.make{
                    type = "item",
                    name = "vespene-gas",
                }
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = LuaFluidPrototype.make{
                type = "fluid",
                name = "vespene-gas",
            }
        end)

        it(":localised_name", function()
            assert.are.same(object.localised_name, {"fluid-name.vespene-gas"})
        end)

        it(":type", function()
            local pType
            assert.error(function()
                pType = object.type
            end)
        end)

        it("-- parent properties", function()
            assert.are.equals(object.name, "vespene-gas")
        end)
    end)
end)
