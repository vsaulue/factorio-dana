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

local ClassLogger = require("lua/logger/ClassLogger")
local StdoutLoggerBackend = require("lua/logger/backends/StdoutLoggerBackend")

describe("ClassLogger", function()
    local cLogger

    before_each(function()
        cLogger = ClassLogger.new{
            className = "TestLogger",
        }
    end)

    it(".new()", function()
        assert.are.equals(cLogger.className, "TestLogger")
        assert.is_not_nil(cLogger.warn)
    end)

    describe(":assert", function()
        it("-- (true)", function()
            cLogger:assert(true, "foobar")
        end)

        it("-- (false)", function()
            assert.error(function()
                cLogger:assert(false, "foobar")
            end)
        end)
    end)

    describe(":assertField()", function()
        it("-- valid", function()
            local object = {
                foo = false,
            }
            local ret = cLogger:assertField(object, "foo")
            assert.is_false(ret)
        end)

        it("-- invalid", function()
            assert.error(function()
                cLogger:assertField({}, "foo")
            end)
        end)
    end)

    describe(":assertFieldType()", function()
        it("-- valid", function()
            local object = {
                bar = function() end,
            }
            local ret = cLogger:assertFieldType(object, "bar", "function")
            assert.are.equals(ret, object.bar)
        end)

        it("-- field not set", function()
            assert.error(function()
                cLogger:assertFieldType(object, "bar", "nil")
            end)
        end)

        it("-- wrong type", function()
            local object = {
                bar = function() end,
            }
            assert.error(function()
                cLogger:assertFieldType(object, "bar", "table")
            end)
        end)
    end)

    it(":error()", function()
        assert.error(function()
            cLogger:error("Epic fail !")
        end)
    end)

    it(":warn()", function()
        stub(StdoutLoggerBackend, "logToUsers")
        cLogger:warn("Not a fail !")
        assert.stub(StdoutLoggerBackend.logToUsers).was.called()
    end)
end)
