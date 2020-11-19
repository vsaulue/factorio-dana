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

local MockMetatable = require("lua/testing/mocks/MockMetatable")

describe("MockMetatable", function()
    it(".new() -- valid", function()
        local metatable = MockMetatable.new{
            className = "foobar",
            __index = function() end,
            __newindex = function() end,
        }
        assert.is_true(metatable.autoLoaded)
        assert.are.equals(metatable.cLogger.className, metatable.className)
        assert.is_not_nil(metatable.cLogger.error)
    end)

    describe(":makeSubclass()", function()
        local BaseMetatable
        local DerivedMetatable
        local derived

        before_each(function()
            BaseMetatable = MockMetatable.new{
                className = "base",
                __index = function(self, index)
                    return {self, "base", index}
                end,
                __newindex = function(self, index, value)
                    rawset(self, index, {self, "base", value})
                end,
            }
            DerivedMetatable = BaseMetatable:makeSubclass{
                className = "derived",
                getters = {
                    foobar = function(self)
                        return {self, "derived", "foo"}
                    end,
                },
                fallbackGetter = function(self, index)
                    local result = nil
                    if index == "fallback" then
                        result = {self, "derived", "back"}
                    end
                    return (result ~= nil), result
                end,
                setters = {
                    barfoo = function(self, value)
                        rawset(self, "barfoo", {self, "derived", value})
                    end,
                },
            }
            derived = {}
            setmetatable(derived, DerivedMetatable)
        end)

        it("-- autoLoaded", function()
            assert.is_true(DerivedMetatable.autoLoaded)
        end)

        it("-- className", function()
            assert.are.equals(DerivedMetatable.className, "derived")
        end)

        it("-- __index", function()
            assert.are.same(derived.kilroy, {derived, "base", "kilroy"})
            assert.are.same(derived.foobar, {derived, "derived", "foo"})
            assert.are.same(derived.fallback, {derived, "derived", "back"})
        end)

        it("-- __setindex", function()
            derived.kilroy = "was here"
            assert.are.same(rawget(derived, "kilroy"), {derived, "base", "was here"})
            derived.barfoo = "wololo"
            assert.are.same(rawget(derived, "barfoo"), {derived, "derived", "wololo"})
        end)
    end)
end)
