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

local LuaForce = require("lua/testing/mocks/LuaForce")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaForce", function()
    local recipes = {
        a = {},
        b = {},
    }

    local force
    before_each(function()
        force = LuaForce.make(recipes)
    end)

    it(".make()", function()
        assert.are.same(force, MockObject.make{
            recipes = {
                a = MockObject.make{
                    force = force,
                    prototype = recipes.a,
                },
                b = MockObject.make{
                    force = force,
                    prototype = recipes.b,
                },
            },
        })
    end)

    describe(":recipes", function()
        it("-- read", function()
            assert.are.equals(force.recipes.a.prototype, recipes.a)
        end)

        it("-- write", function()
            assert.error(function()
                force.recipes.b = "denied"
            end)
        end)
    end)
end)
