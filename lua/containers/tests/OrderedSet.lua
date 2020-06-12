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

local OrderedSet = require("lua/containers/OrderedSet")

local assertSetEqualToArray
local setSampleSet

describe("OrderedSet", function()
    local set

    before_each(function()
        set = OrderedSet.new()
    end)

    after_each(function()
        set = nil
    end)

    it("constructor", function()
        assert.are.equals(set.forward[OrderedSet.Begin], OrderedSet.End)
        assert.are.equals(set.backward[OrderedSet.End], OrderedSet.Begin)
    end)

    it("newFromArray", function()
        local Values = {"All", "your", "base", "are", "belong", "to", "us", count=7}
        local newSet = OrderedSet.newFromArray(Values)
        assertSetEqualToArray(newSet, Values)
    end)

    it(":insertAfter()", function()
        setSampleSet(set)
        set:insertAfter(4, -5)

        assertSetEqualToArray(set, {-9, 4, -5, "Kilroy was here"})
    end)

    it(":pushBack()", function()
        setSampleSet(set)
        set:pushBack(123)
        assertSetEqualToArray(set, {-9, 4, "Kilroy was here", 123})
    end)

    it(":pushFront()", function()
        setSampleSet(set)
        set:pushFront(9000)
        assertSetEqualToArray(set, {9000, -9, 4, "Kilroy was here"})
    end)

    it(":remove()", function()
        setSampleSet(set)
        set:remove(-9)
        assertSetEqualToArray(set, {4, "Kilroy was here"})
    end)
end)

-- Fills the given OrderedSet with some hardcoded values.
--
-- Args:
-- * set; OrderedSet object to fill.
--
setSampleSet = function(set)
    local Values = {-9, 4, "Kilroy was here"}
    local prevValue = OrderedSet.Begin
    for _,value in ipairs(Values) do
        set.forward[prevValue] = value
        set.backward[value] = prevValue
        prevValue = value
    end

    set.forward[prevValue] = OrderedSet.End
    set.backward[OrderedSet.End] = prevValue
end

-- Tests the sequence of values in an OrderedSet.
--
-- Args:
-- * set: OrderedSet to check.
-- * array: Lua array containing the sequence of expected values.
--
assertSetEqualToArray = function(set, array)
    local value = OrderedSet.Begin
    for _,expectedValue in ipairs(array) do
        value = set.forward[value]
        assert.are.equals(value, expectedValue)
    end
    assert.are.equals(set.forward[value], OrderedSet.End)

    value = OrderedSet.End
    for i=#array,1,-1 do
        local expectedValue = array[i]
        value = set.backward[value]
        assert.are.equals(value, expectedValue)
    end
    assert.are.equals(set.backward[value], OrderedSet.Begin)
end
