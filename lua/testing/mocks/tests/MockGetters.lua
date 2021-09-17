-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

describe("MockGetters", function()
    it(".hide()", function()
        local Metatable = CommonMockObject.Metatable:makeSubclass{
            className = "Groot",
            getters = {
                valid = MockGetters.hide("valid"),
            },
        }
        local object = CommonMockObject.make(nil, Metatable)

        local flag
        assert.error(function()
            flag = object.valid
        end)
    end)

    describe(".validDeepCopy()", function()
        local Metatable
        local object

        before_each(function()
            Metatable = MockObject.Metatable:makeSubclass{
                className = "TheLieIsACake",
                getters = {
                    barfoo = MockGetters.validDeepCopy("barfoo"),
                },
            }
            local data = {
                barfoo = {
                    someTable = {
                        bar = "foo",
                        [1] = true,
                    },
                    [false] = "wololo",
                },
            }
            data.barfoo.someTable.moreTable = data.barfoo.someTable
            object = MockObject.make(data, Metatable)
        end)

        it("-- valid", function()
            local barfoo = object.barfoo
            assert.are.same(barfoo, {
                someTable = {
                    bar = "foo",
                    [1] = true,
                    moreTable = barfoo.someTable,
                },
                [false] = "wololo",
            })
        end)

        it("-- invalid", function()
            MockObject.invalidate(object)
            local barfoo
            assert.error(function()
                barfoo = object.barfoo
            end)
        end)
    end)

    describe(".validReadOnly()", function()
        local Metatable
        local object

        before_each(function()
            Metatable = MockObject.Metatable:makeSubclass{
                className = "Leeroy",
                getters = {
                    foobar = MockGetters.validReadOnly("foobar")
                },
            }
            object = MockObject.make({
                foobar = { many = "welps", handle = 'it'},
            }, Metatable)
        end)

        it("-- invalid object", function()
            MockObject.invalidate(object)
            local foobar
            assert.error(function()
                foobar = object.foobar
            end)
        end)

        it("-- read access", function()
            local foobar = object.foobar
            assert.are.equals(foobar.many, "welps")
            assert.is_nil(foobar.dkp)
        end)

        it("-- write access", function()
            local foobar = object.foobar
            assert.error(function()
                foobar.many = "DKP"
            end)
        end)
    end)

    describe(".validShallowCopy()", function()
        local Metatable
        local object

        before_each(function()
            Metatable = MockObject.Metatable:makeSubclass{
                className = "Pentakill",
                getters = {
                    murdered = MockGetters.validShallowCopy("murdered"),
                },
            }
            object = MockObject.make({
                murdered = {
                    Nunu = {"Disco"},
                    Yuumi = {"Jungle"},
                },
            }, Metatable)
        end)

        it("-- valid", function()
            local internalValue = MockObject.getData(object).murdered
            local readValue = object.murdered
            assert.are.same(readValue, {
                Nunu = {"Disco"},
                Yuumi = {"Jungle"},
            })
            assert.are_not.equals(readValue, internalValue)

            -- Shallow copy check
            readValue.Garen = "Demaciaaaaaaaaaaaa"
            assert.are.same(internalValue, {
                Nunu = {"Disco"},
                Yuumi = {"Jungle"},
            })

            -- Non-deep copy check
            readValue.Yuumi[2] = "W AFK"
            assert.are.same(internalValue.Yuumi, {"Jungle", "W AFK"})
        end)

        it("-- invalid", function()
            MockObject.invalidate(object)
            local foo
            assert.error(function()
                foo = object.murdered
            end)
        end)
    end)

    describe(".validTrivial()", function()
        local Metatable
        local object

        before_each(function()
            Metatable = CommonMockObject.Metatable:makeSubclass{
                className = "PowerUpTheBassCanon",
                getters = {
                    giantDad = MockGetters.validTrivial("giantDad"),
                },
            }
            object = CommonMockObject.make({
                giantDad = "chaos10zweihander",
            }, Metatable)
        end)

        it("-- valid", function()
            assert.are.equals(object.giantDad, "chaos10zweihander")
        end)

        it("-- invalid", function()
            MockObject.invalidate(object)
            local foo
            assert.error(function()
                foo = object.giantDad
            end)
        end)
    end)
end)
