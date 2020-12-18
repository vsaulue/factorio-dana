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

local MinDistParams = require("lua/query/params/MinDistParams")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("MinDistParams", function()
    local object
    before_each(function()
        object = MinDistParams.new()
    end)

    it(".copy()", function()
        object.allowOtherIntermediates = "a"
        object.intermediateSet["foobar"] = true
        object.maxDepth = 7
        local o2 = MinDistParams.copy(object)
        assert.are.same(o2, {
            allowOtherIntermediates = true,
            intermediateSet = {
                foobar = true,
            },
            maxDepth = 7,
        })
        assert.are_not.equals(object, o2)
    end)

    it(".new()", function()
        assert.are.same(object, {
            allowOtherIntermediates = false,
            intermediateSet = {},
        })
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = object,
            metatableSetter = MinDistParams.setmetatable,
        }
    end)
end)
