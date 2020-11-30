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
require("lua/testing/mocks/CheckboxGuiElement")
require("lua/testing/mocks/ChooseElemGuiElement")
require("lua/testing/mocks/EmptyGuiElement")
require("lua/testing/mocks/FlowGuiElement")
require("lua/testing/mocks/FrameGuiElement")
require("lua/testing/mocks/LabelGuiElement")
require("lua/testing/mocks/LineGuiElement")
require("lua/testing/mocks/ScrollPaneGuiElement")
require("lua/testing/mocks/SpriteButtonGuiElement")
require("lua/testing/mocks/SpriteGuiElement")
require("lua/testing/mocks/TextfieldGuiElement")

-- Helper to generate mocks for LuaGuiElement objects.
--
local LuaGuiElement = {
    -- Creates a new LuaGuiElement object (with the appropriate subtype).
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * mockArgs: table. Same as AbstractGuiElement.abstractMake().
    --
    -- Returns: The new LuaGuiElement object.
    --
    make = function(args, mockArgs)
        return AbstractGuiElement.make(args, mockArgs)
    end,
}

return LuaGuiElement
