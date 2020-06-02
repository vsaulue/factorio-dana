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

local Aabb = require("lua/canvas/Aabb")
local AbstractCanvasObject = require("lua/canvas/objects/AbstractCanvasObject")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local BaseMetatable = AbstractCanvasObject.Metatable
local Metatable

-- Class used to draw a rectangle on a Canvas.
--
-- RO fields: all from AbstractCanvasObject.
--
local CanvasRectangle = ErrorOnInvalidRead.new{
    -- Creates a new CanvasRectangle, and its associated rendering id.
    --
    -- Args:
    -- * initData: Table passed to the rendering API to generate the rectangle id.
    --
    -- Returns: The new CanvasRectangle object.
    --
    makeFromInitData = function(initData)
        return AbstractCanvasObject.new({
            id = rendering.draw_rectangle(initData),
            type = "rectangle",
        }, Metatable)
    end,

    -- Restores the metatable of a CanvasRectangle instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the CanvasRectangle class.
Metatable = {
    __index = {
        -- Implements AbstractCanvasObject:isCollidingWithAabb()
        --
        isCollidingWithAabb = function(self, aabb)
            local id = self.id
            local ltPos = rendering.get_left_top(id).position
            local rbPos = rendering.get_right_bottom(id).position
            return ltPos.x <= aabb.xMax and ltPos.y <= aabb.yMax and rbPos.x >= aabb.xMin and rbPos.y >= aabb.yMin
        end,
    },
}
setmetatable(Metatable, { __index = BaseMetatable})
setmetatable(Metatable.__index, { __index = BaseMetatable.__index})

AbstractCanvasObject.Factory:registerClass("rectangle", CanvasRectangle)
return CanvasRectangle
