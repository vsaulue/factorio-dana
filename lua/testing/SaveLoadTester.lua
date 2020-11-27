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

local checkMetatables
local copy
local make
local mustCopy
local ValidTypes

-- Class used to validate the code used to restore metatables after a save/load cycle.
--
-- The copy is performed as follows, depending on types
-- * number/boolean/int: copy by value.
-- * table:
-- **  if the metatable contains the `autoLoaded` flag, the reference is directly reused without copy.
-- **  else: deep recursive copy of all all keys/values.
-- * other: error
--
-- The autoLoaded flag in the metatable can be used my mock classes, for object whose Metatable are
-- automatically restored by the game itself.
--
-- Fields:
-- * input: table with the following fields:
-- **  metatableSetter: function(x). Function to call to restore the metatable of `objects`.
-- **  objects: table. Contains all the original objects to save/load in the test.
-- * mapping[table] -> table. Map giving the copy of an object from `original`.
--
local SaveLoadTester = {
    -- Runs a save/load test.
    --
    -- Args:
    -- * testInput: Table containing the following fields.
    -- **  objects: table. Original object to save/load for the test.
    -- **  metatableSetter: function(x). Function to call on the copy to restore the metatables.
    --
    run = function(testInput)
        local self = make(testInput)
        testInput.metatableSetter(self.copiedObjects)
        checkMetatables(self, self.input.objects, {}, {count = 0}, false)
    end,
}

-- Checks that all metatables are identical between the original & the copy.
--
-- Args:
-- * self: SaveLoadTester.
-- * object: any. Current element being checked.
-- * visited: Set<table>. Table that have already been checked.
-- * stack: array. Contains the sequence of field indices from `self.input.objects` to `objects`.
-- **  count: int. Top index of the array.
-- * isIndex: boolean. True if `object` is a key in the parent table. False for a value.
--
checkMetatables = function(self, object, visited, stack, isIndex)
    if type(object) == "table" and self.mapping[object] and not visited[object] then
        local mapping = self.mapping
        visited[object] = true
        if getmetatable(object) ~= getmetatable(mapping[object]) then
            local msg = {"Metatable mismatch at: objects"}
            for i=1,stack.count do
                table.insert(msg, " -> ")
                table.insert(msg, tostring(stack[i]))
            end
            if isIndex then
                table.insert(msg, "    -- index")
            else
                table.insert(msg, "    -- value")
            end
            error(table.concat(msg))
        end
        local count = stack.count + 1
        stack.count = count
        for key,value in next,object do
            stack[count] = key
            checkMetatables(self, key, visited, stack, true)
            checkMetatables(self, value, visited, stack, false)
        end
        stack.count = count -1
    end
end

-- Generates the copy of a specific object.
--
-- Args:
-- * self: SaveLoadTester object.
-- * object: any. Value to copy.
--
-- Returns: The copy of `object` to use for the test.
--
copy = function(self, object)
    local objectType = type(object)
    if not ValidTypes[objectType] then
        error("Invalid type to serialize: " .. objectType)
    end

    local result
    if objectType == "table" then
        result = self.mapping[object]
        if not result then
            if mustCopy(self, object) then
                result = object
            else
                result = {}
                self.mapping[object] = result
                for key,value in next,object do
                    result[copy(self, key)] = copy(self, value)
                end
            end
        end
    else
        result = object
    end
    return result
end

-- Creates a new SaveLoadTester object.
--
-- Args:
-- * testInput: Table to use as the `input` field.
--
-- Returns: The new SaveLoadTester object.
--
make = function(testInput)
    local result = {
        input = testInput,
        mapping = {},
    }

    result.copiedObjects = copy(result, testInput.objects)

    return result
end

-- Evaluates if a table should be deep-copied, or just passed by reference.
--
-- Args:
-- * self: SaveLoadTester object.
-- * object: Table to test.
--
-- Returns: boolean. True to deep-copy, false to copy by reference.
--
mustCopy = function(self, object)
    local metatable = getmetatable(object)
    return metatable and type(metatable) == "table" and metatable.autoLoaded
end

-- Lua types allowed to be copied.
ValidTypes = {
    boolean = true,
    number = true,
    string = true,
    table = true,
}

return SaveLoadTester
