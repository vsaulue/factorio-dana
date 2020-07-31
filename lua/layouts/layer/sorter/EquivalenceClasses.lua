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
local ReversibleArray = require("lua/containers/ReversibleArray")

-- Class holding the equivalence classes of a layer.
--
-- Equivalence classes are entries that share exactly the same LayerLinkIndex set as parents.
-- Roots are a particular equivalence class, with 0 parent.
--
-- RO fields:
-- * classes[parents]: Set of equivalence classes, indexed by an Array holding the parent set.
-- * order: ReversibleArray with all parents, used to impose an order inside the keys of classes.
-- * roots: Array containing all the roots.
--
-- Methods:
-- * addToClass: Adds an entry to the specified equivalence class.
--
local EquivalenceClasses = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

-- Implementation stuff (private scope).
local getClass

-- Metatable of the EquivalenceClasses class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds an entry to the specified equivalence class.
        --
        -- Args:
        -- * self: EquivalenceClasses object.
        -- * parents: Array of parent elements, identifying the class. May be modified and/or internally
        -- used: don't modify it after passing it to this method.
        -- * entry: Entry to add to the equivalence class.
        --
        addToClass = function(self, parents, entry)
            getClass(self, parents):pushBack(entry)
        end,
    },
}

-- Gets the specified equivalence class. Creates an empty one if needed.
--
-- Args:
-- * self: EquivalenceClasses object.
-- * parents: Array of parent elements, identifying the class. May be modified and/or internally
-- used: don't modify it after passing it to this method.
--
-- Returns: The equivalence class associated with parents (created empty if needed).
--
getClass = function(self, parents)
    local result = nil
    if parents.count == 0 then
        result = self.roots
    else
        local allParentsPresent = true
        for i=1,parents.count do
            local parent = parents[i]
            if not rawget(self.order.reverse, parent) then
                allParentsPresent = false
                self.order:pushBack(parent)
            end
        end
        parents:sort(self.order.reverse)
        if allParentsPresent then
            for classIndex,class in pairs(self.classes) do
                if classIndex == parents then
                    result = class
                    break
                end
            end
        end
        if not result then
            result = Array.new()
            self.classes[parents] = result
        end
    end
    return result
end

-- Creates a new EquivalenceClasses object.
--
-- Returns: The new EquivalenceClasses object.
--
function EquivalenceClasses.new()
    local result = ErrorOnInvalidRead.new{
        classes = ErrorOnInvalidRead.new(),
        order = ReversibleArray.new(),
        roots = Array.new(),
    }
    setmetatable(result, Metatable)
    return result
end

return EquivalenceClasses
