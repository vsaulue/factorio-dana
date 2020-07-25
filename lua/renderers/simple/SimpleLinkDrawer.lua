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
-- RW Fields:
-- * drawSpriteAtSrc: True to add a sprite on the line near the `from` end.
-- * drawSpriteAtDest: True to add a sprite on the line near the `to` end.
-- * makeTriangle: True to draw a proper arrow. False for just a line.
--
-- RO Fields:
-- * canvas: Canvas object on which to draw the line.
-- * circleArgs: Argument passed to Canvas:newLine() to draw the connection circles.
-- * from: Coordinates of the start of the arrow.
-- * lineArgs: Argument passed to Canvas:newLine() to draw the segment.
-- * lineTo: Coordinates of the end of the line (might be slightly different from `to` for cosmetic reasons).
-- * spriteArgs: Argument passed to Canvas:newSprite() to draw the sprites.
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
        object.drawSpriteAtDest = object.drawSpriteAtDest or false
        object.drawSpriteAtSrc = object.drawSpriteAtDest or false
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
        object.spriteArgs = {
            target = {},
            x_scale = SimpleConfig.LinkSpriteScale,
            y_scale = SimpleConfig.LinkSpriteScale,
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

            local makeTriangle = self.makeTriangle
            local drawSpriteAtDest = self.drawSpriteAtDest
            local drawSpriteAtSrc = self.drawSpriteAtSrc
            if makeTriangle or drawSpriteAtDest or drawSpriteAtSrc then
                local from = self.from
                local dx = to.x - from.x
                local dy = to.y - from.y
                local remainingLength = math.sqrt(dx * dx + dy * dy)
                local nx = dx / remainingLength
                local ny = dy / remainingLength

                if makeTriangle then
                    local TriangleLength = SimpleConfig.LinkArrowLength
                    if remainingLength > 1.5 * TriangleLength then
                        canvas:newPolygon(self.triangleArgs)
                        lineTo.x = to.x - nx * TriangleLength
                        lineTo.y = to.y - ny * TriangleLength
                        remainingLength = remainingLength - TriangleLength
                    end
                end


                local SpriteLength = SimpleConfig.LinkSpriteScale
                local lengthOffset = 0.6 * SpriteLength
                local spriteArgs = self.spriteArgs
                local target = spriteArgs.target
                if drawSpriteAtDest then
                    if remainingLength > SpriteLength then
                        target.x = lineTo.x - nx * lengthOffset
                        target.y = lineTo.y - ny * lengthOffset
                        canvas:newSprite(self.spriteArgs)
                        remainingLength = remainingLength - SpriteLength
                    end
                end
                if drawSpriteAtSrc then
                    if remainingLength > SpriteLength then
                        target.x = from.x + nx * lengthOffset
                        target.y = from.y + ny * lengthOffset
                        canvas:newSprite(self.spriteArgs)
                    end
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

        -- Set the path of the sprite to draw near the ends of the line.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * value: New SpritePath to set.
        --
        setSpritePath = function(self, value)
            self.spriteArgs.sprite = value
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