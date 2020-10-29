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

local LuaFluidEnergySourcePrototype = require("lua/testing/mocks/LuaFluidEnergySourcePrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaFluidEnergySourcePrototype", function()
    local rawData
    before_each(function()
        rawData = {
            fluid_box = {
                production_type = "input-output",
                filter = "water",
            },
            type = "fluid",
        }
    end)

    describe(".make()", function()
        it("-- valid", function()
            local object = LuaFluidEnergySourcePrototype.make(rawData)
            assert.are.same(object, MockObject.make{
                fluid_box = MockObject.make{
                    production_type = "input-output",
                    filter = "water",
                },
            })
        end)

        it("-- wrong type", function()
            rawData.type = "void"
            assert.error(function()
                LuaFluidEnergySourcePrototype.make(rawData)
            end)
        end)

        it("-- wrong fluid_box", function()
            rawData.fluid_box = nil
            assert.error(function()
                LuaFluidEnergySourcePrototype.make(rawData)
            end)
        end)
    end)

    it(":fluid_box", function()
        local object = LuaFluidEnergySourcePrototype.make(rawData)
        assert.are.equals(MockObject.getData(object).fluid_box, object.fluid_box)
    end)
end)
