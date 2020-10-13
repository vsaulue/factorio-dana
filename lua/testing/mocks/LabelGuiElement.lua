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

local cLogger = ClassLogger.new{className = "LabelGuiElement"}

local ElementType
local Metatable

-- Subtype for LuaGuiElement objects of type "label".
--
-- Inherits from AbstractGuiElement.
--
local LabelGuiElement = {
    -- Creates a new LabelGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * player_index: int. Index of the player owning the new element.
    -- * parent: LabelGuiElement. Parent element that will own the new element (may be nil).
    --
    -- Returns: The new LabelGuiElement object.
    --
    make = function(args, player_index, parent)
        local result = AbstractGuiElement.abstractMake(args, player_index, parent, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))

        return result
    end,
}

-- Value in the "type" field.
ElementType = "label"

-- Metatable of the LabelGuiElement class.
Metatable = {
    -- Flag for SaveLoadTester.
    autoLoaded = true,

    __index = AbstractGuiElement.Metatable.__index,

    __newindex = AbstractGuiElement.Metatable.__newindex,
}

AbstractGuiElement.registerClass(ElementType, LabelGuiElement)
return LabelGuiElement
