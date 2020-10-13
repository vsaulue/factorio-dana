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

local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("SaveLoadTester", function()
    describe(".run()", function()
        it("-- valid", function()
            local m1 = {}
            local m2 = {}
            local key = {}
            local object = {
                elem1 = {},
                elem2 = {
                    [key] = true,
                },
                [4] = "kilroy",
            }
            setmetatable(key, m1)
            setmetatable(object.elem1, m2)

            SaveLoadTester.run{
                objects = object,
                metatableSetter = function(object)
                    setmetatable(object.elem1, m2)
                    for k in pairs(object.elem2) do
                        setmetatable(k, m1)
                    end
                end,
            }
        end)

        it("-- valid with autoLoaded", function()
            local aMetatable = {autoLoaded = true}
            local object = {
                foo = {
                    bar = {},
                }
            }
            setmetatable(object.foo.bar, aMetatable)

            SaveLoadTester.run{
                objects = object,
                metatableSetter = function(object) end,
            }
        end)

        it("-- invalid (saving function)", function()
            assert.error(function()
                SaveLoadTester.run{
                    objects = {
                        foo = function() end,
                    },
                    metatableSetter = function() end,
                }
            end)
        end)

        it("-- invalid (missing metatable)", function()
            local m1 = {}
            local objects = {
                foo = {},
                bar = {},
            }
            setmetatable(objects, m1)
            setmetatable(objects.bar, m1)
            assert.error(function()
                SaveLoadTester.run{
                    objects = objects,
                    metatableSetter = function(object)
                        setmetatable(object, m1)
                    end,
                }
            end)
        end)

        it("--invalid (too many metatables)", function()
            local m1 = {}
            local objects = {
                foo = {},
            }
            assert.error(function()
                SaveLoadTester.run{
                    objects = objects;
                    metatableSetter = function(object)
                        setmetatable(object, m1)
                    end,
                }
            end)
        end)

        it("--invalid (wrong metatable)", function()
            local m1 = {}
            local m2 = {}
            local object = {}
            setmetatable(object, m1)
            assert.error(function()
                SaveLoadTester.run{
                    objects = object,
                    metatableSetter = function(object)
                        setmetatable(object, m2)
                    end,
                }
            end)
        end)
    end)
end)
