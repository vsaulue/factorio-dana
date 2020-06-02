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

local BaseMetatable = AbstractCanvasObject.Metatable
local Metatable

local minmax
local signOfScalarProduct

-- Class used to draw a line on a Canvas.
--
-- RO fields: all from AbstractCanvasObject.
--
local CanvasLine = ErrorOnInvalidRead.new{
    -- Creates a new CanvasLine, and its associated rendering id.
    --
    -- Args:
    -- * initData: Table passed to the rendering API to generate the line id.
    --
    -- Returns: The new CanvasLine object.
    --
    makeFromInitData = function(initData)
        return AbstractCanvasObject.new({
            id = rendering.draw_line(initData),
            type = "line",
        }, Metatable)
    end,

    -- Restores the metatable of a CanvasLine instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the CanvasLine class.
Metatable = {
    __index = {
        -- Implements AbstractCanvasObject:isCollidingWithAabb()
        --
        isCollidingWithAabb = function(self, aabb)
            local id = self.id
            local fromPos = rendering.get_from(id).position
            local toPos = rendering.get_to(id).position
            local xMin,xMax = minmax(fromPos.x, toPos.x)
            local yMin,yMax = minmax(fromPos.y, toPos.y)
            local result = xMax >= aabb.xMin and aabb.xMax >= xMin and yMax >= aabb.yMin and aabb.yMax >= yMin
            if result then
                local xNormal = toPos.y - fromPos.y
                local yNormal = - (toPos.x - fromPos.x)
                local signSum = signOfScalarProduct(xNormal, yNormal, fromPos.x - aabb.xMin, fromPos.y - aabb.yMin)
                              + signOfScalarProduct(xNormal, yNormal, fromPos.x - aabb.xMin, fromPos.y - aabb.yMax)
                              + signOfScalarProduct(xNormal, yNormal, fromPos.x - aabb.xMax, fromPos.y - aabb.yMin)
                              + signOfScalarProduct(xNormal, yNormal, fromPos.x - aabb.xMax, fromPos.y - aabb.yMax)
                result = (-4 < signSum) and (signSum < 4)
            end
            return result
        end,
    }
}
setmetatable(Metatable, { __index = BaseMetatable})
setmetatable(Metatable.__index, { __index = BaseMetatable.__index})

-- Computes the minimum & maximum of 2 arguments.
--
-- Args:
-- * a: A float.
-- * b/ Another float.
--
-- Returns:
-- * min(a,b)
-- * max(a,b)
--
minmax = function(a,b)
    local min = a
    local max = b
    if min > max then
        min = b
        max = a
    end
    return min,max
end

-- Computes the sign of a dot product between 2d vectors.
--
-- Args:
-- * x1: X coordinate of the first vector.
-- * y1: X coordinate of the first vector.
-- * x2: X coordinate of the second vector.
-- * y2: X coordinate of the second vector.
--
-- Returns: a value representing the sign (positive -> 1; negative -> -1: else -> 0).
--
signOfScalarProduct = function(x1, y1, x2, y2)
    local scalar = x1*x2 + y1*y2
    local result = 0
    if scalar < 0 then
        result = -1
    elseif scalar > 0 then
        result = 1
    end
    return result
end

AbstractCanvasObject.Factory:registerClass("line", CanvasLine)
return CanvasLine
