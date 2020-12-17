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
local SinkParams = require("lua/query/params/SinkParams")

describe("SinkParams", function()
    local object
    before_each(function()
        object = SinkParams.new()
    end)

    it(".new()", function()
        assert.is_false(object.filterNormal)
        assert.is_false(object.filterRecursive)
        assert.is_not_nil(object.indirectThreshold)
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = object,
            metatableSetter = SinkParams.setmetatable,
        }
    end)
end)