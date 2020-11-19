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
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger

local ElementType
local Metatable
local setText

-- Subtype for LuaGuiElement objects of type "textfield".
--
-- Inherits from AbstractGuiElement.
--
-- Implemented fields & methods:
-- * allow_negative
-- * numeric
-- * text
-- + AbstractGuiElement
--
local TextfieldGuiElement = {
    -- Creates a new TextfieldGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * mockArgs: table. Same as AbstractGuiElement.abstractMake().
    --
    -- Returns: The new TextfieldGuiElement object.
    --
    make = function(args, mockArgs)
        local result = AbstractGuiElement.abstractMake(args, mockArgs, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))
        local data = MockObject.getData(result)

        data.numeric = not not args.numeric
        data.allow_negative = not not args.allow_negative
        setText(data, args.text or "")

        return result
    end,
}

-- Metatable of the TextfieldGuiElement class.
Metatable = AbstractGuiElement.Metatable:makeSubclass{
    className = "TextfieldGuiElement",

    getters = {
        allow_negative = MockGetters.validTrivial("allow_negative"),
        numeric = MockGetters.validTrivial("numeric"),
        text = MockGetters.validTrivial("text"),
    },

    setters = {
        allow_negative = function(self, value)
            local data = MockObject.getData(self, "allow_negative")
            data.allow_negative = not not value
            setText(data, data.text)
        end,

        numeric = function(self, value)
            local data = MockObject.getData(self, "numeric")
            data.numeric = not not value
            setText(data, data.text)
        end,

        text = function(self, value)
            local data = MockObject.getData(self, "text")
            setText(data, value)
        end,
    },
}
cLogger = Metatable.cLogger

-- Value in the "type" field.
ElementType = "textfield"

-- Sets the "text" field of a TextfieldGuiElement.
--
-- Args:
-- * selfData: table. Internal data of the TextfieldGuiElement.
-- * value: string. New value of the "text" field.
--
setText = function(selfData, value)
    cLogger:assert(type(value) == "string", "Invalid 'text' value (string expected).")
    local finalValue = value
    if selfData.numeric then
        local number = tonumber(value)
        if number then
            if (not selfData.allow_negative) and (number < 0) then
                finalValue = ""
            end
        else
            finalValue = ""
        end
    end
    selfData.text = finalValue
end

AbstractGuiElement.registerClass(ElementType, TextfieldGuiElement)
return TextfieldGuiElement
