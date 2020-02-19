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

local Array = require("lua/containers/Array")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Queue = require("lua/containers/Queue")

-- Container: a set with strict partial ordering function.
--
-- RO fields:
-- * dependencyGraph[lElem][gElem]: 2-dim map of stored relations.
-- * greaterThan[lElem][gElem]: 2-dim map, true if lElem < gElem. Not set otherwise.
--
-- Methods:
-- * addRelation: Sets the relation order between 2 elements.
-- * insert: Adds a new element to the set.
-- * makeLinearExtension: Makes a linear extension of this partial order.
--
local StrictPoset = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

-- Implementation stuff (private scope).
local has

-- Metatable of the StrictPoset class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        addRelation = nil,

        insert = nil,

        makeLinearExtension = nil,
    },
}

-- Tests if an element is present in the poset.
--
-- Args:
-- * self: StrictPoset object.
-- * element: Element to test.
--
-- Returns: True if element is in this set.
--
has = function(self, element)
    return rawget(self.dependencyGraph, element) ~= nil
end

-- Sets the relation order between 2 elements.
--
-- Args:
-- * self: StrictPoset object.
-- * lowerElement: Lower element of the relation.
-- * greaterElement: Greater element of the relation.
--
function Metatable.__index.addRelation(self, lowerElement, greaterElement)
    assert(has(self, greaterElement), "StrictPoset: Invalid element.")
    assert(has(self, lowerElement), "StrictPoset: Invalid element.")
    assert(greaterElement ~= lowerElement, "StrictPoset: attempt to make an element lower than itself.")
    assert(not self.greaterThan[lowerElement][greaterElement], "StrictPoset: conflicting relations.")

    self.dependencyGraph[lowerElement][greaterElement] = true
    for great2 in pairs(self.greaterThan[greaterElement]) do
        self.greaterThan[lowerElement][great2] = true
    end
    self.greaterThan[lowerElement][greaterElement] = true
end

-- Adds a new element to the set.
--
-- Args:
-- * self: StrictPoset object.
-- * element: New element to add.
--
function Metatable.__index.insert(self, element)
    if not has(self, element) then
        self.dependencyGraph[element] = {}
        self.greaterThan[element] = {}
    end
end

-- Makes a linear extension of this partial order.
--
-- Kahn's algorithm.
--
-- Args:
-- * self: StrictPoset object.
--
-- Returns: Array with all the element of `self`, in a compatible order.
--
function Metatable.__index.makeLinearExtension(self)
    local result = Array.new()
    local todo = Queue.new()
    local counts = ErrorOnInvalidRead.new()
    for element in pairs(self.dependencyGraph) do
        counts[element] = 0
    end
    for element,depSet in pairs(self.dependencyGraph) do
        for greater in pairs(depSet) do
            counts[greater] = counts[greater] + 1
        end
    end
    for element,count in pairs(counts) do
        if count == 0 then
            todo:enqueue(element)
        end
    end

    while todo.count > 0 do
        local element = todo:dequeue()
        for greater in pairs(self.dependencyGraph[element]) do
            local count = counts[greater] - 1
            if count == 0 then
                todo:enqueue(greater)
            end
            counts[greater] = count
        end
        result:pushBack(element)
    end

    return result
end

-- Creates a new empty StrictPoset object.
--
-- Returns: The new StrictPoset object.
--
function StrictPoset.new()
    local result = {
        dependencyGraph = ErrorOnInvalidRead.new(),
        greaterThan = ErrorOnInvalidRead.new(),
    }
    setmetatable(result, Metatable)
    return result
end

return StrictPoset
