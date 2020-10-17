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

describe("MockObject", function()
    local object

    before_each(function()
        object = MockObject.make()
    end)

    it(".make() -- custom data & metatable", function()
        local m = {}
        local d = {}
        local o2 = MockObject.make(d, m)
        assert.are.equals(MockObject.getDataIfValid(o2), d)
        assert.are.equals(getmetatable(o2), m)
    end)

    it("-- invalid read", function()
        assert.error(function()
            print(object.foo)
        end)
    end)

    it("-- invalid write", function()
        assert.error(function()
            object.bar = "foo"
        end)
    end)

    describe(".getData() & .invalidate()", function()
        it("-- valid", function()
            local data = MockObject.getData(object)
            assert.is_not_nil(data)
        end)

        it("-- invalid, no index", function()
            MockObject.invalidate(object)
            assert.error(function()
                MockObject.getData(object)
            end)
        end)

        it("-- invalid, index", function()
            MockObject.invalidate(object)
            assert.error(function()
                MockObject.getData(object, "foobar")
            end)
        end)
    end)

    describe(".getDataIfValid() & .invalidate()", function()
        it("-- valid", function()
            local data = MockObject.getDataIfValid(object)
            assert.is_not_nil(data)
        end)

        it("-- invalidated", function()
            MockObject.invalidate(object)
            local data = MockObject.getDataIfValid(object)
            assert.is_nil(data)
        end)
    end)
end)
