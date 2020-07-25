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

local Metatable

-- Class to draw line segment of links.
--
-- RO Fields:
-- * canvas: Canvas object on which to draw the line.
-- * lineArgs: Argument passed to Canvas:drawLine().
--
local SimpleLinkDrawer = ErrorOnInvalidRead.new{
    -- Creates a new SimpleLinkDrawer object.
    --
    -- Args:
    -- * object: Table to turn into a SimpleLinkDrawer object.
    --
    new = function(object)
        cLogger:assertField(object, "canvas")
        object.lineArgs = {
            draw_on_ground = true,
            from = {},
            to = {},
            width = SimpleConfig.LinkLineWitdh,
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
            return self.canvas:newLine(self.lineArgs)
        end,

        -- Set the category index of the link.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * value: The new category index value.
        --
        setLinkCategoryIndex = function(self, value)
            self.lineArgs.color = SimpleConfig.LinkCategoryToColor[value]
        end,

        -- Set the source end point of this link.
        --
        -- Args:
        -- * self: SimpleLinkDrawer object.
        -- * x: New X coordinate of this end.
        -- * y: New Y coordinate of this end.
        --
        setFrom = function(self, x, y)
            local from = self.lineArgs.from
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
            local to = self.lineArgs.to
            to.x = x
            to.y = y
        end,
    }
}

return SimpleLinkDrawer