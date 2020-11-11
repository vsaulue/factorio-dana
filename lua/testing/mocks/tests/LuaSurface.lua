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

local LuaSurface = require("lua/testing/mocks/LuaSurface")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaSurface", function()
    describe(".make()", function()
        local cArgs
        before_each(function()
            cArgs = {
                index = 4,
                name = "sivuan",
            }
        end)

        it("-- valid", function()
            local object = LuaSurface.make(cArgs)
            local data = MockObject.getData(object)
            assert.are.equals(data.index, 4)
            assert.are.equals(data.name, "sivuan")
        end)

        it("-- invalid index", function()
            cArgs.index = nil
            assert.error(function()
                LuaSurface.make(cArgs)
            end)
        end)

        it("-- invalid name", function()
            cArgs.name = nil
            assert.error(function()
                LuaSurface.make(cArgs)
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = LuaSurface.make{
                index = 7,
                name = "FusRohDah",
            }
        end)

        it(":index", function()
            assert.are.equals(object.index, 7)
        end)

        it(":name", function()
            assert.are.equals(object.name, "FusRohDah")
        end)
    end)
end)
