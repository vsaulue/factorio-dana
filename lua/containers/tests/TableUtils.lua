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

local TableUtils = require("lua/containers/TableUtils")

describe("TableUtils", function()
    describe(".getOrInitTableField()", function()
        it("-- Access to existing field", function()
            local aVal = {}
            local object = {
                a = aVal,
            }
            local result = TableUtils.getOrInitTableField(object, "a")
            assert.are.equals(object.a, aVal)
            assert.are.equals(result, aVal)
        end)

        it("-- Access to a new field", function()
            local object = {
                a = {},
            }
            local result = TableUtils.getOrInitTableField(object, "b")
            assert.is_true(type(result) == "table")
            assert.are.equals(object.b, result)
        end)
    end)
end)
