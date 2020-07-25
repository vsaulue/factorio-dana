-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local SimpleConfig = require("lua/renderers/simple/SimpleConfig")

local cLogger = ClassLogger.new{className = "SimpleLinkDrawer"}

local ArrowVertices
local Metatable

-- Class to draw line segment of links.
--
-- RO Fields:
-- * canvas: Canvas object on which to draw the line.
-- * circleArgs: Argument passed to Canvas:newLine() to draw the connection circles.
-- * from: Coordinates of the start of the arrow.
-- * makeTriangle: True to draw a proper arrow. False for just a line.
-- * lineArgs: Argument passed to Canvas:newLine() to draw the segment.
-- * lineTo: Coordinates of the end of the line (might be slightly different from `to` for cosmetic reasons).
-- * to: Coordinates of the target of the arrow.
-- * triangleArgs: Arguments passed to Canvas:newPolygon() to draw the arrow.
--
local SimpleLinkDrawer = ErrorOnInvalidRead.new{
    -- Creates a new SimpleLinkDrawer object.
    --
    -- Args:
    -- * object: Table to turn into a SimpleLinkDrawer object.
    --
    new = function(object)
        cLogger:assertField(object, "canvas")
        object.from = {}
        object.to = {}
        object.lineTo = {}
        object.makeTriangle = object.makeTriangle or false
        object.circleArgs = {
            draw_on_ground = true,
            filled = true,
            radius = SimpleConfig.LinkCircleRadius,
        }
        object.lineArgs = {
            draw_on_ground = true,
            from = object.from,
            to = object.lineTo,
            width = SimpleConfig.LinkLineWitdh,
        }
        object.triangleArgs = {
            orientation_target = object.lineArgs.from,
            target = object.to,
            vertices = ArrowVertices,
        }
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the SimpleLinkDrawer class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Draws the line described in the internal state of this object.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        --
        -- Returns: The created CanvasLine.
        --
        draw = function(self)
            local canvas = self.canvas
            local lineTo = self.lineTo
            local to = self.to

            lineTo.x = to.x
            lineTo.y = to.y

            if self.makeTriangle then

                local from = self.from
                local dx = to.x - from.x
                local dy = to.y - from.y
                local length = math.sqrt(dx * dx + dy * dy)

                local TriangleLength = SimpleConfig.LinkArrowLength
                if length > 1.5 * TriangleLength then
                    canvas:newPolygon(self.triangleArgs)
                    lineTo.x = to.x - dx / length * TriangleLength
                    lineTo.y = to.y - dy / length * TriangleLength
                end
            end

            return canvas:newLine(self.lineArgs)
        end,

        -- Draws a connection circle either at `from` or `to` coordinates.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * isFrom: True to center the circle on `from`. False for `to`.
        --
        -- Returns: The created CanvasCircle.
        --
        drawCircle = function(self, isFrom)
            local circleArgs = self.circleArgs
            if isFrom then
                circleArgs.target = self.from
            else
                circleArgs.target = self.to
            end
            return self.canvas:newCircle(circleArgs)
        end,

        -- Set the category index of the link.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * value: The new category index value.
        --
        setLinkCategoryIndex = function(self, value)
            local color = SimpleConfig.LinkCategoryToColor[value]
            self.lineArgs.color = color
            self.triangleArgs.color = color
            self.circleArgs.color = color
        end,

        -- Set the source end point of this link.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * x: New X coordinate of this end.
        -- * y: New Y coordinate of this end.
        --
        setFrom = function(self, x, y)
            local from = self.from
            from.x = x
            from.y = y
        end,

        -- Set the destination end point of this link.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * x: New X coordinate of this end.
        -- * y: New Y coordinate of this end.
        --
        setTo = function(self, x, y)
            local to = self.to
            to.x = x
            to.y = y
        end,
    }
}

-- Vertex coordinates to build the triangle end of the arrow.
ArrowVertices = {
    { target = {0,0}},
    { target = {
        -math.tan(SimpleConfig.LinkArrowAngle/2) * SimpleConfig.LinkArrowLength,
        - SimpleConfig.LinkArrowLength}
    },
    { target = {
        math.tan(SimpleConfig.LinkArrowAngle/2) * SimpleConfig.LinkArrowLength,
        - SimpleConfig.LinkArrowLength}
    },
}

return SimpleLinkDrawer