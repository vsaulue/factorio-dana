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

local AbstractGuiElement = require("lua/testing/mocks/AbstractGuiElement")
local ClassLogger = require("lua/logger/ClassLogger")
local GuiDirection = require("lua/testing/mocks/GuiDirection")

local cLogger = ClassLogger.new{className = "FrameGuiElement"}

local ElementType
local ForwardedIndex
local Metatable

-- Subtype for LuaGuiElement objects of type "frame".
--
-- Inherits from AbstractGuiElement.
--
local FrameGuiElement = {
    -- Creates a new FrameGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * player_index: int. Index of the player owning the new element.
    -- * parent: FrameGuiElement. Parent element that will own the new element (may be nil).
    --
    -- Returns: The new FrameGuiElement object.
    --
    make = function(args, player_index, parent)
        local result = AbstractGuiElement.abstractMake(args, player_index, parent, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))
        local data = AbstractGuiElement.getDataIfValid(result)

        local direction = cLogger:assertField(args, "direction")
        data.direction = GuiDirection.check(direction)

        return result
    end,
}

-- Value in the "type" field.
ElementType = "frame"

-- Name of the fields which can directly be returned from the internal table via __index.
ForwardedIndex = {
    direction = true,
}

-- Metatable of the FrameGuiElement class.
Metatable = {
    -- Flag for SaveLoadTester.
    autoLoaded = true,

    __index = function(self, index)
        local data = AbstractGuiElement.getDataIfValid(self)
        if data then
            if ForwardedIndex[index] then
                return data[index]
            end
        end

        return AbstractGuiElement.Metatable.__index(self, index)
    end,

    __newindex = AbstractGuiElement.Metatable.__newindex,
}

AbstractGuiElement.registerClass(ElementType, FrameGuiElement)
return FrameGuiElement