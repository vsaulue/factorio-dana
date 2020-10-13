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

local Closeable = require("lua/class/Closeable")

describe("Closeable", function()
    describe(".safeCloseField()", function()
        it("-- nil", function()
            local object = {}
            Closeable.safeCloseField(object, "foo")
            assert.is_nil(object.foo)
        end)

        it("-- not nil", function()
            local object = {
                someField = {
                    flag = false,
                    close = function(self)
                        self.flag = true
                    end,
                },
            }
            local someField = object.someField
            Closeable.safeCloseField(object, "someField")
            assert.is_nil(object.someField)
            assert.is_true(someField.flag)
        end)
    end)
end)
