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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ErrorOnInvalidRead", function()
    local object

    before_each(function()
        object = ErrorOnInvalidRead.new{
            foo = "bar",
        }
    end)

    describe(".setmetatable()", function()
        local Metatable = {
            __index = {
                madness = "Spartaaaaaaa",
            },
        }

        local makeObject = function()
            local result = {}
            setmetatable(result, Metatable)
            return result
        end

        local resetMetatable = function(object)
            setmetatable(object, Metatable)
        end

        it("-- no key/value metatable", function()
            SaveLoadTester.run{
                objects = object,
                metatableSetter = ErrorOnInvalidRead.setmetatable,
            }
        end)

        it("-- key metatable", function()
            SaveLoadTester.run{
                objects = ErrorOnInvalidRead.new{
                    [makeObject()] = "wololo",
                },
                metatableSetter = function(object)
                    ErrorOnInvalidRead.setmetatable(object, resetMetatable)
                end,
            }
        end)

        it("-- value metatable", function()
            SaveLoadTester.run{
                objects = ErrorOnInvalidRead.new{
                    wololo = makeObject(),
                },
                metatableSetter = function(object)
                    ErrorOnInvalidRead.setmetatable(object, nil, resetMetatable)
                end,
            }
        end)
    end)

    it("-- invalid read", function()
        assert.error(function()
            print(object.fOO)
        end)
    end)

    it("-- valid read", function()
        assert.are.equals(object.foo, "bar")
    end)
end)
