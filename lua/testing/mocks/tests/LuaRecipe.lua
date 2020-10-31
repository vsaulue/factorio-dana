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

local LuaRecipe = require("lua/testing/mocks/LuaRecipe")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaRecipe", function()
    local force = {}
    local prototype = {}

    local object
    before_each(function()
        object = LuaRecipe.make{
            force = force,
            prototype = prototype,
        }
    end)

    it(".make()", function()
        assert.are.same(object, MockObject.make{
            force = force,
            prototype = prototype,
        })
    end)

    it(":force", function()
        assert.are.equals(object.force, force)
    end)

    it(":prototype", function()
        assert.are.equals(object.prototype, prototype)
    end)
end)
