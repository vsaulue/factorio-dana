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

local AbstractCanvasObject = require("lua/canvas/objects/AbstractCanvasObject")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local Metatable

-- Class used to draw a circle on a Canvas.
--
-- RO fields: all from AbstractCanvasObject.
--
local CanvasCircle = ErrorOnInvalidRead.new{
    -- Creates a new CanvasCircle, and its associated rendering id.
    --
    -- Args:
    -- * initData: Table passed to the rendering API to generate the circle id.
    --
    -- Returns: The new CanvasCircle object.
    --
    makeFromInitData = function(initData)
        return AbstractCanvasObject.new({
            id = rendering.draw_circle(initData),
            type = "circle",
        }, Metatable)
    end,

    -- Restores the metatable of a CanvasCircle instance, and all its owned objects.
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the CanvasCircle class.
Metatable = {
    __index = {
        -- Implements AbstractCanvasObject:isCollidingWithAabb().
        --
        -- Base algorithm from https://stackoverflow.com/a/402010.
        --
        isCollidingWithAabb = function(self, aabb)
            local aXmin, aYmin = aabb.xMin, aabb.yMin
            local hXlen, hYlen = (aabb.xMax - aXmin)/2, (aabb.yMax - aYmin)/2

            local id = self.id
            local radius = rendering.get_radius(id)
            local center = rendering.get_target(id).position

            local xDelta = math.abs(aXmin + hXlen - center.x)
            local yDelta = math.abs(aYmin + hYlen - center.y)

            local result = (xDelta <= hXlen + radius) and (yDelta <= hYlen + radius)
            if result and (xDelta >= hXlen) and (yDelta >= hYlen) then
                local xx = xDelta - hXlen
                local yy = yDelta - hYlen
                result = (xx * xx + yy * yy) <= radius * radius
            end
            return result
        end,
    },
}
setmetatable(Metatable, { __index = AbstractCanvasObject.Metatable})
setmetatable(Metatable.__index, { __index = AbstractCanvasObject.Metatable.__index})

AbstractCanvasObject.Factory:registerClass("circle", CanvasCircle)
return CanvasCircle
