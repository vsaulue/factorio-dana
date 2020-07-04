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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local makeVerticalPusher
local PusherArgs

-- Helper library to help placing GUI elements in a specific way.
--
local GuiAlign = ErrorOnInvalidRead.new{
    -- Creates a new LuaGuiElement in with a centered vertical_align.
    --
    -- Args:
    -- * parent: LuaGuiElement in which the new element will be created.
    -- * childArgs: Table used to create the new element.
    --
    -- Returns: The new LuaGuiElement object.
    --
    makeVerticallyCentered = function(parent, childArgs)
        local flow = parent.add{
            type = "flow",
            direction = "vertical",
        }
        makeVerticalPusher(flow)
        local result = flow.add(childArgs)
        result.style.vertical_align = "center"
        makeVerticalPusher(flow)
        return result
    end,
}

-- Creates a new vertical pusher.
--
-- A pusher is a stretchable empty element, to indicate the GUI engine that a space can be resized
-- to meet the align constraints of other elements.
--
-- Args:
-- * parent: LuaGuiElement in which the pusher will be created.
makeVerticalPusher = function(parent)
    local result = parent.add(PusherArgs)
    result.style.vertically_stretchable = true
    return result
end

-- Parameters to construct a pusher.
PusherArgs = {
    type = "empty-widget",
    style = "draggable_space_header",
}

return GuiAlign
