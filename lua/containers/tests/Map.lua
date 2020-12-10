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

local Map = require("lua/containers/Map")

describe("Map", function()
    describe(".copy()", function()
        it("-- default functions", function()
            local m1 = {
                foo = "bar",
                [false] = 1,
                [2] = false,
            }
            local m2 = Map.copy(m1)
            assert.are.same(m1, m2)
            assert.are_not.equals(m1, m2)
        end)

        it("-- custom copy functions", function()
            local m1 = {
                [{kId="k1"}] = {vId="v1"},
                [{kId="k2"}] = {vId="v2"},
            }
            local keyCopy = function(key)
                return key.kId
            end
            local valueCopy = function(value)
                return value.vId
            end
            local m2 = Map.copy(m1, keyCopy, valueCopy)
            assert.are.same(m2, {
                k1 = "v1",
                k2 = "v2",
            })
        end)
    end)

    describe(".equals()", function()
        local testEquals = function(m1, m2, valueEquals, expected)
            assert.are.equals(expected, Map.equals(m1, m2, valueEquals))
            assert.are.equals(expected, Map.equals(m2, m1, valueEquals))
        end

        it("--default function", function()
            local m1 = {
                [false] = true,
            }
            local m2 = {
                [false] = true,
            }
            testEquals(m1, m2, nil, true)

            m2.foo = "bar"
            testEquals(m1, m2, nil, false)
        end)

        it("-- custom function", function()
            local m1 = {
                [1] = {value = 1},
                bar = {value = "foo"},
            }
            local m2 = {
                [1] = {value = 1},
                bar = {value = "foo"},
            }
            local valueEquals = function(v1,v2)
                return v1.value == v2.value
            end
            testEquals(m1, m2, valueEquals, true)

            m2.bar.value = "nope"
            testEquals(m1, m2, valueEquals, false)
        end)
    end)
end)
