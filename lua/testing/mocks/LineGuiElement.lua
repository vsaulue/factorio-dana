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
local GuiDirection = require("lua/testing/mocks/GuiDirection")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger
local ElementType
local Metatable

-- Subtype for LuaGuiElement objects of type "line".
--
-- Inherits from AbstractGuiElement.
--
local LineGuiElement = {
    -- Creates a new LineGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * mockArgs: table. Same as AbstractGuiElement.abstractMake().
    --
    -- Returns: The new LineGuiElement object.
    --
    make = function(args, mockArgs)
        local result = AbstractGuiElement.abstractMake(args, mockArgs, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))
        local data = MockObject.getData(result)

        local direction = cLogger:assertField(args, "direction")
        data.direction = GuiDirection.check(direction)

        return result
    end,

    -- Metatable of the LineGuiElement class.
    Metatable = AbstractGuiElement.Metatable:makeSubclass{
        className = "LineGuiElement",

        getters = {
            direction = MockGetters.validTrivial("direction"),
        },
    },
}

cLogger = LineGuiElement.Metatable.cLogger

-- Value in the "type" field.
ElementType = "line"

Metatable = LineGuiElement.Metatable

AbstractGuiElement.registerClass(ElementType, LineGuiElement)
return LineGuiElement
