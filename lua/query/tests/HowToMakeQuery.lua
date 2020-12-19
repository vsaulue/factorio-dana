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

local HowToMakeQuery = require("lua/query/HowToMakeQuery")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("HowToMakeQuery", function()
    local query
    before_each(function()
        query = HowToMakeQuery.new{
            destParams = {
                intermediateSet = {
                    a = true,
                },
            },
        }
    end)

    it(".new()", function()
        assert.is_not_nil(query.destParams)
        assert.is_not_nil(query.execute)
        assert.is_not_nil(query.destParams.intermediateSet.a)
        assert.is_false(query.destParams.allowOtherIntermediates)
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = query,
            metatableSetter = HowToMakeQuery.setmetatable,
        }
    end)

    it(":copy()", function()
        query.destParams.maxDepth = 123
        local o2 = query:copy()
        assert.are.same(query, o2)
        assert.are.equals(o2.destParams.maxDepth, 123)
        assert.are_not.equals(query.destParams, o2.destParams)
    end)
end)
