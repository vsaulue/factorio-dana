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

local MockObject = require("lua/testing/mocks/MockObject")
local MockReadOnlyWrapper = require("lua/testing/mocks/MockReadOnlyWrapper")

describe("MockReadOnlyWrapper", function()
    local data
    local object

    before_each(function()
        data = {
            [1] = -1,
        }
        object = MockReadOnlyWrapper.make(data)
    end)

    it(".make()", function()
        assert.are.equal(getmetatable(object).className, "MockReadOnlyWrapper")
        assert.are.equal(MockObject.getDataIfValid(object), data)
    end)

    describe("-- read access", function()
        assert.are.equals(object[1], -1)
    end)

    describe("-- write access", function()
        assert.error(function()
            object[1] = -2
        end)
    end)

    describe("", function()
        local pairTest = function(pairFunction)
            assert.are.same({pairFunction(data)}, {pairFunction(object)})
        end

        it("-- ipairs", function()
            pairTest(ipairs)
        end)

        it("-- pairs", function()
            pairTest(pairs)
        end)
    end)
end)
