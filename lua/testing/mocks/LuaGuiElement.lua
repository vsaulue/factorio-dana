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

-- Import all subtypes to populate the factory.
require("lua/testing/mocks/ButtonGuiElement")
require("lua/testing/mocks/ChooseElemGuiElement")
require("lua/testing/mocks/EmptyGuiElement")
require("lua/testing/mocks/FlowGuiElement")
require("lua/testing/mocks/FrameGuiElement")
require("lua/testing/mocks/LabelGuiElement")
require("lua/testing/mocks/SpriteGuiElement")

-- Helper to generate mocks for LuaGuiElement objects.
--
local LuaGuiElement = {
    -- Creates a new LuaGuiElement object (with the appropriate subtype).
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * player_index: int. Index of the player owning the new element.
    -- * parent: AbstractGuiElement. Parent element that will own the new element (may be nil).
    --
    -- Returns: The new LuaGuiElement object.
    --
    make = function(args, player_index, parent)
        return AbstractGuiElement.make(args, player_index, parent)
    end,
}

return LuaGuiElement
