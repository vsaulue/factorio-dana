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

local Set = require("lua/containers/Set")

describe("Set",function()
    describe(".areEquals()", function()
        local runEqualTest = function(set1, set2, expectedResult)
            assert.are.equals(Set.areEquals(set1, set2), expectedResult)
            assert.are.equals(Set.areEquals(set2, set1), expectedResult)
        end

        it("-- true (both empty)", function()
            runEqualTest({}, {}, true)
        end)

        it("-- false (one empty)", function()
            runEqualTest({a = true}, {}, false)
        end)

        it("-- true (non-trivial)", function()
            local set1 = {
                a = true,
                b = 0,
                z = true,
            }
            local set2 = {
                a = 1,
                b = 2,
                z = true,
            }
            runEqualTest(set1, set2, true)
        end)

        it("-- false (non-trivial)", function()
            local set1 = {
                a = true,
                b = true,
            }
            local set2 = {
                a = true,
                b = true,
                z = true,
            }
            runEqualTest(set1, set2, false)
        end)
    end)

    describe(".checkCount()", function()
        it("-- true (empty & 0)", function()
            assert.is_true(Set.checkCount({}, 0))
        end)

        it("-- false (empty & 1)", function()
            assert.is_false(Set.checkCount({}, 1))
        end)

        it("-- true (5)", function()
            local set = {
                the = true,
                cake = true,
                is = true,
                a = true,
                lie = true,
            }
            assert.is_true(Set.checkCount(set, 5))
        end)

        it("-- false (non-empty)", function()
            local set = {
                Kilroy = true,
                was = true,
                here = true,
            }
            assert.is_false(Set.checkCount(set, 2))
            assert.is_false(Set.checkCount(set, 4))
        end)
    end)

    describe(".checkSingleton()", function()
        it("-- true", function()
            assert.is_true(Set.checkSingleton({z = true}, "z"))
        end)

        it("-- false (wrong value)", function()
            assert.is_false(Set.checkSingleton({z = true}, "a"))
        end)

        it("-- false (empty)", function()
            assert.is_false(Set.checkSingleton({}, "z"))
        end)

        it("-- false (2 elements)", function()
            assert.is_false(Set.checkSingleton({z = true, a = true}, "z"))
        end)
    end)

    it(".count()", function()
        local result = Set.count{}
        assert.are.equals(result, 0)

        result = Set.count{foo = true, bar = true}
        assert.are.equals(result, 2)
    end)
end)
