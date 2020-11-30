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
local SpritePath = require("lua/testing/mocks/SpritePath")

local cLogger

local ElementType
local Metatable
local setSprite

-- Subtype for LuaGuiElement objects of type "sprite".
--
-- Inherits from AbstractGuiElement.
--
-- Implemented fields & methods:
-- * sprite
-- + AbstractGuiElement
--
local SpriteGuiElement = {
    -- Creates a new SpriteGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * mockArgs: table. Same as AbstractGuiElement.abstractMake().
    --
    -- Returns: The new SpriteGuiElement object.
    --
    make = function(args, mockArgs)
        local result = AbstractGuiElement.abstractMake(args, mockArgs, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))
        local data = MockObject.getData(result)

        setSprite(data, args.sprite)

        return result
    end,
}

-- Metatable of the SpriteGuiElement class.
Metatable = AbstractGuiElement.Metatable:makeSubclass{
    className = "SpriteGuiElement",

    getters = {
        sprite = MockGetters.validTrivial("sprite"),
    },

    setters = {
        sprite = function(self, value)
            local data = MockObject.getData(self)
            setSprite(data, value)
        end
    },
}
cLogger = Metatable.cLogger

-- Value in the "type" field.
ElementType = "sprite"

-- Set the "sprite" value of this element.
--
-- Args:
-- * selfData: table. Internal data of the SpriteGuiElement.
-- * value: string or nil. New value of the "sprite" field.
--
setSprite = function(selfData, value)
    if value ~= nil then
        SpritePath.check(value)
    end
    selfData.sprite = value
end

AbstractGuiElement.registerClass(ElementType, SpriteGuiElement)
return SpriteGuiElement
