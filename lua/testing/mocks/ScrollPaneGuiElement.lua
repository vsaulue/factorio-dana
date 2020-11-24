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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger

local checkScrollPolicy
local ElementType
local Metatable
local ValidScrollPolicies

-- Subtype for LuaGuiElement objects of type "scroll-pane".
--
-- Inherits from AbstractGuiElement.
--
-- Implemented fields & methods:
-- * horizontal_scroll_policy
-- * vertical_scroll_policy
-- + AbstractGuiElement
--
local ScrollPaneGuiElement = ErrorOnInvalidRead.new{
    -- Creates a new ScrollPaneGuiElement object.
    --
    -- Args:
    -- * args: table. Constructor argument of a LuaGuiElement in Factorio.
    -- * mockArgs: table. Same as AbstractGuiElement.abstractMake().
    --
    -- Returns: The new ScrollPaneGuiElement object.
    --
    make = function(args, mockArgs)
        local result = AbstractGuiElement.abstractMake(args, mockArgs, Metatable)
        cLogger:assert(args.type == ElementType, "Incorrect type value: " .. tostring(args.type))

        local data = MockObject.getData(result)
        data.horizontal_scroll_policy = checkScrollPolicy(args.horizontal_scroll_policy or "auto")
        data.vertical_scroll_policy = checkScrollPolicy(args.vertical_scroll_policy or "auto")

        return result
    end,
}

-- Metatable of the ScrollPaneGuiElement class.
Metatable = AbstractGuiElement.Metatable:makeSubclass{
    className = "ScrollPaneGuiElement",

    getters = {
        horizontal_scroll_policy = MockGetters.validTrivial("horizontal_scroll_policy"),
        vertical_scroll_policy = MockGetters.validTrivial("vertical_scroll_policy"),
    },

    setters = {
        horizontal_scroll_policy = function(self, value)
            local data = MockObject.getData(self, "horizontal_scroll_policy")
            data.horizontal_scroll_policy = checkScrollPolicy(value)
        end,

        vertical_scroll_policy = function(self, value)
            local data = MockObject.getData(self, "vertical_scroll_policy")
            data.vertical_scroll_policy = checkScrollPolicy(value)
        end,
    }
}
cLogger = Metatable.cLogger

-- Checks the value of a scroll_policy field.
--
-- Args:
-- * value: string. Value to test.
--
checkScrollPolicy = function(value)
    if not ValidScrollPolicies[value] then
        cLogger:error("Invalid scroll_policy: " .. tostring(value))
    end
    return value
end

-- Value in the "type" field.
ElementType = "scroll-pane"

-- Valid values for the scroll_policy fields.
ValidScrollPolicies = {
    always = true,
    auto = true,
    ["auto-and-reserve-space"] = true,
    never = true,
}

AbstractGuiElement.registerClass(ElementType, ScrollPaneGuiElement)
return ScrollPaneGuiElement
