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

local AbstractNode = require("lua/layouts/AbstractNode")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local TableUtils = require("lua/containers/TableUtils")

local cLogger = ClassLogger.new{className = "HalfCircleRectNode"}

local Metatable
local NodeShapeType

-- AbstractNode specialisation for node made of a half-circle and a rectangle.
--
-- Inherits from AbstractNode.
--
-- Fields:
-- * radius: Radius of the circle (& height of the rectangle).
-- * xCenter: X coordinate of the center of the circle.
-- * yCenter: Y coordinate of the center of the circle.
--
local HalfCircleRectNode = ErrorOnInvalidRead.new{
    -- Creates a new HalfCircleRectNode object.
    --
    -- Args:
    -- * object: Table to turn into a HalfCircleRectNode object.
    --
    -- Returns: The argument turned into a RectangleNode object.
    --
    new = function(object)
        cLogger:assertField(object, "radius")
        object.type = NodeShapeType
        return AbstractNode.new(object, Metatable)
    end,

    -- Restores the metatable of a HalfCircleRectNode instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the HalfCircleRectNode class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractNode:drawOnCanvas().
        drawOnCanvas = function(self, canvas, rendererArgs)
            local target = TableUtils.getOrInitTableField(rendererArgs, "target")
            target.x = self.xCenter
            target.y = self.yCenter
            rendererArgs.radius = self.radius
            local circle = canvas:newCircle(rendererArgs)

            local left_top = TableUtils.getOrInitTableField(rendererArgs, "left_top")
            left_top.x = self.xCenter - self.radius
            left_top.y = self.yCenter - self.radius
            local right_bottom = TableUtils.getOrInitTableField(rendererArgs, "right_bottom")
            right_bottom.x = self.xCenter + self.radius
            right_bottom.y = self.yCenter

            return {
                [circle] = true,
                [canvas:newRectangle(rendererArgs)] = true,
            }
        end,

        -- Implements AbstractNode:getAABB().
        getAABB = function(self)
            local cx = self.xCenter
            local cy = self.yCenter
            local r = self.radius
            return cx - r, cx + r, cy - r, cy + r
        end,

        -- Implements AbstractNode:getMiddle().
        getMiddle = function(self)
            return self.xCenter, self.yCenter
        end,

        -- Implements AbstractNode:getXMin().
        getXMin = function(self)
            return self.xCenter - self.radius
        end,

        -- Implements AbstractNode:getXLength().
        getXLength = function(self, withMargins)
            local halfResult = self.radius
            if withMargins then
                halfResult= halfResult + self.xMargin
            end
            return 2 * halfResult
        end,

        -- Implements AbstractNode:getYLength().
        getYLength = function(self, withMargins)
            local halfResult = self.radius
            if withMargins then
                halfResult= halfResult + self.yMargin
            end
            return 2 * halfResult
        end,

        -- Implements AbstractNode:setXMin().
        setXMin = function(self, xMin)
            self.xCenter = xMin + self.radius
        end,

        -- Implements AbstractNode:setYMin().
        setYMin = function(self, yMin)
            self.yCenter = yMin + self.radius
        end,

        -- Implements AbstractNode:yProject().
        yProject = function(self, x, isFromLowY)
            local result
            if isFromLowY then
                result = self.yCenter - self.radius
            else
                local r = self.radius
                local dx = self.xCenter - x
                local dy2 = r * r - dx * dx
                cLogger:assert(dy2 >= 0, "Projection failed (X coordinate out of range).")
                local dy = math.sqrt(dy2)

                result = self.yCenter + dy
            end
            return result
        end,
    },
}

-- Unique name for this AbstractNode subtype.
NodeShapeType = "halfCircleRect"

AbstractNode.Factory:registerClass(NodeShapeType, HalfCircleRectNode)
return HalfCircleRectNode
