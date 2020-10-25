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

local LuaFluidBoxPrototype = require("lua/testing/mocks/LuaFluidBoxPrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaFluidBoxPrototype", function()
    describe(".make()", function()
        it("-- valid", function()
            local object = LuaFluidBoxPrototype.make{
                filter = "foobar",
                production_type = "input-output",
            }
            local data = MockObject.getData(object)
            assert.are.same(data,{
                filter = "foobar",
                production_type = "input-output",
            })
        end)

        it("-- invalid filter", function()
            assert.error(function()
                LuaFluidBoxPrototype.make{
                    filter = 45,
                }
            end)
        end)

        it("-- invalid production_type", function()
            assert.error(function()
                LuaFluidBoxPrototype.make{
                    production_type = "output-input",
                }
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = LuaFluidBoxPrototype.make{
                filter = "wololo",
                production_type = "output",
            }
        end)

        describe(":filter", function()
            it("-- read", function()
                assert.are.equals(object.filter, "wololo")
            end)

            it("-- write", function()
                assert.error(function()
                    object.filter = "denied"
                end)
            end)
        end)

        describe(":production_type", function()
            it("-- read", function()
                assert.are.equals(object.production_type, "output")
            end)

            it("-- write", function()
                assert.error(function()
                    object.production_type = "input"
                end)
            end)
        end)
    end)
end)
