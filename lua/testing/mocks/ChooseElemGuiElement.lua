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
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local checkElemValue
local cLogger
local ElementType
local Metatable
local ValidElemTypes

-- Subtype for LuaGuiElement objects of type "choose-elem-button".
--
-- Inherits from AbstractGuiElement.
--
local ChooseElemGuiElement = {
    -- Creates a new ChooseElemGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * mockArgs: table. Same as AbstractGuiElement.abstractMake().
    --
    -- Returns: The new ChooseElemGuiElement object.
    --
    make = function(args, mockArgs)
        local result = AbstractGuiElement.abstractMake(args, mockArgs, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))
        local data = MockObject.getData(result)

        local elemType = args.elem_type
        cLogger:assert(ValidElemTypes[elemType], "Invalid elem_type: " .. tostring(elemType))
        data.elem_type = elemType

        local elemValue = args.elem_value
        if elemValue ~= nil then
            data.elem_value = checkElemValue(elemValue)
        end

        return result
    end,

    -- Metatable of the ChooseElemGuiElement class.
    Metatable = AbstractGuiElement.Metatable:makeSubclass{
        className = "ChooseElemGuiElement",

        getters = {
            elem_type = MockGetters.validTrivial("elem_type"),
            elem_value = MockGetters.validTrivial("elem_value"),
        },

        setters = {
            elem_value = function(self, value)
                local data = MockObject.getData(self)
                data.elem_value = checkElemValue(value)
            end,
        },
    }
}

-- Checks that the argument is valid for the "elem_value" field.
--
-- Args:
-- * elemValue: any. Value to check.
--
-- Returns: string. The argument.
--
checkElemValue = function(elemValue)
    if elemValue ~= nil then
        cLogger:assert(type(elemValue) == "string", "Invalid elem_value (string expected).")
    end
    return elemValue
end

cLogger = ChooseElemGuiElement.Metatable.cLogger

-- Value in the "type" field.
ElementType = "choose-elem-button"

Metatable = ChooseElemGuiElement.Metatable

-- Set<string>. Valid values for the "elem_type" field.
ValidElemTypes = {
    achievement = true,
    decorative = true,
    entity = true,
    equipment = true,
    fluid = true,
    item = true,
    ["item-group"] = true,
    tile = true,
    recipe = true,
    -- signal = true, not supported yet.
    technology = true,
}

AbstractGuiElement.registerClass(ElementType, ChooseElemGuiElement)
return ChooseElemGuiElement
