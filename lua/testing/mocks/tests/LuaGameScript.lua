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

local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaGameScript", function()
    local gameScript

    before_each(function()
        gameScript = LuaGameScript.make{
            fluid = {
                water = {
                    type = "fluid",
                    name = "water",
                },
            },
            item = {
                wood = {
                    type = "item",
                    name = "wood",
                },
            },
        }
    end)

    describe(".make()", function()
        it("-- fluid_prototypes", function()
            local data = MockObject.getDataIfValid(gameScript)

            local water = data.fluid_prototypes.water
            assert.are.equals(water.name, "water")
            assert.are.equals(getmetatable(water).className, "LuaFluidPrototype")

            local wood = data.item_prototypes.wood
            assert.are.equals(wood.name, "wood")
            assert.are.equals(getmetatable(wood).className, "LuaItemPrototype")
        end)
    end)

    describe(":fluid_prototypes", function()
        it("-- read", function()
            local water = gameScript.fluid_prototypes.water
            assert.are.equals(water.name, "water")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.fluid_prototypes.water = "denied"
            end)
        end)
    end)

    describe(":item_prototypes", function()
        it("-- read", function()
            local wood = gameScript.item_prototypes.wood
            assert.are.equals(wood.name, "wood")
        end)

        it("-- write", function()
            assert.error(function()
                gameScript.item_prototypes.wood = "denied"
            end)
        end)
    end)
end)
