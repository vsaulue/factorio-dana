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

local ClassLogger = require("lua/logger/ClassLogger")

local cLogger = ClassLogger.new{className = "ItemSlot"}

local checkValidForRead
local Getters
local Metatable
local Setters

-- Class for a slot in an inventory.
--
-- This is the thing a LuaItemStack points at.
--
-- RO Fields:
-- * count: int. Number of items in this slot.
-- * name: string. Name of the LuaItemPrototype.
--
local ItemSlot = {
    -- Creates a new ItemSlot object.
    --
    -- Returns: ItemSlot.
    --
    new = function()
        return setmetatable({}, Metatable)
    end,
}

-- Metatable of the ItemSlot class.
Metatable = {
    __index = {
        -- Directly reads a value for LuaItemStack.
        --
        -- Args:
        -- * self: ItemSlot.
        -- * index: string. Name of the LuaItemStack property to read.
        --
        -- Returns: any. The appropriate value.
        --
        get = function(self, index)
            return Getters[index](self)
        end,

        -- Directly sets a LuaItemStack value.
        --
        -- Args:
        -- * self: ItemSlot.
        -- * index: string. Name of the LuaItemStack property to set.
        -- * value: any. New value to set.
        --
        set = function(self, index, value)
            return Setters[index](self, value)
        end,

        -- Fully replaces the content of this slot.
        --
        -- Args:
        -- * self: ItemSlot.
        -- * value: LuaItemStack or SimpleItemStack or nil. Nil clears the stack.
        --
        setStack = function(self, value)
            if value then
                self.name = value.name
                self.count = value.count
            else
                self.name = nil
                self.count = nil
            end
        end,
    },
}

-- Checks if this slot contains a valid item.
--
-- Args:
-- * self: ItemSlot.
-- * index: any. Index of the field read by the calling function (debug purposes).
--
checkValidForRead = function(self, index)
    if not Getters.valid_for_read(self) then
        cLogger:error("Invalid access at '" .. tostring(index) .. "' (valid_for_read == false).")
    end
end

-- Map[string]: function(ItemSlot). Getters for the LuaItemStack properties with the same index.
Getters = {
    count = function(self)
        checkValidForRead(self, "count")
        return self.count
    end,

    name = function(self)
        checkValidForRead(self, "name")
        return self.name
    end,

    valid_for_read = function(self)
        return (self.name ~= nil)
    end,
}

-- Map[string]: function(ItemSlot). Setters for the LuaItemStack properties with the same index.
Setters = {
    count = function(self, value)
        checkValidForRead(self, "count")
        local parsed = math.floor(tonumber(value))
        cLogger:assert((value == parsed) and (value >= 0), "Invalid count (positive int required).")
        if value == 0 then
            self.name = nil
            self.count = nil
        else
            self.count = value
        end
    end,
}

return ItemSlot
