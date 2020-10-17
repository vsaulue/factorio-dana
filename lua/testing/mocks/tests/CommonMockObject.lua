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

local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local MockObject = require("lua/testing/mocks/MockObject")

describe("CommonMockObject", function()
    describe(".make()", function()
        it("-- no data or metatable", function()
            local object = CommonMockObject.make()
            assert.are.equals(getmetatable(object), CommonMockObject.Metatable)
            assert.is_not_nil(MockObject.getDataIfValid(object))
        end)

        it("-- data + metatable", function()
            local meta = {}
            local data = {
                foo = "bar",
            }
            local object = CommonMockObject.make(data, meta)
            assert.are.equals(getmetatable(object), meta)
            assert.are.equals(MockObject.getDataIfValid(object), data)
        end)
    end)

    describe(".valid", function()
        it("-- true", function()
            local object = CommonMockObject.make()
            assert.is_true(object.valid)
        end)

        it("-- false", function()
            local object = CommonMockObject.make()
            MockObject.invalidate(object)
            assert.is_false(object.valid)
        end)
    end)
end)
