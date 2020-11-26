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

local SimpleItemStack = require("lua/testing/mocks/SimpleItemStack")

describe("SimpleItemStack.make()", function()
    local cArgs
    before_each(function()
        cArgs = {
            name = "coal",
        }
    end)

    it("-- valid", function()
        local object = SimpleItemStack.make(cArgs)
        assert.are.same(object, {
            count = 1,
            name = "coal",
        })
    end)

    it("-- valid + count", function()
        cArgs.count = 3
        local object = SimpleItemStack.make(cArgs)
        assert.are.same(object, {
            name = "coal",
            count = 3,
        })
    end)

    it("-- invalid count", function()
        cArgs.count = 0
        assert.error(function()
            SimpleItemStack.make(cArgs)
        end)
    end)

    it("-- invalid name", function()
        cArgs.name = 987654321
        assert.error(function()
            SimpleItemStack.make(cArgs)
        end)
    end)
end)
