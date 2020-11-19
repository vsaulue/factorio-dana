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

local AbstractFactory = require("lua/class/AbstractFactory")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "AbstractNode"}

-- Class representing a vertex/edge node in a graph layout.
--
-- RO Fields:
-- * xMargin: Margin on the X axis.
-- * yMargin: Margin on the Y axis.
--
local AbstractNode = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractNode instances.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.type
        end,
    },

    -- Creates a new AbstractNode object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractNode object.
    -- * metatable: Metatable to set.
    --
    -- Returns: The argument turned into an AbstractNode object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "type")
        cLogger:assertField(object, "xMargin")
        cLogger:assertField(object, "yMargin")
        setmetatable(object, metatable)
        return object
    end,
}

--[[

Metatable = {
        -- Draws this node on a Canvas.
        --
        -- Args:
        -- * self: AbstractNode object.
        -- * canvas: Canvas object on which to draw the node.
        -- * rendererArgs (modified): Arguments passed to Factorio's rendering API to create the shape.
        --
        -- Returns: A set of CanvasObject.
        --
        drawOnCanvas = function(self, canvas, rendererArgs) end,

        -- Gets the 4 coordinates of the bounding box of this node (without margins).
        --
        -- Args:
        -- * self: AbstractNode object.
        --
        -- Returns:
        -- * Minimum X-axis coordinate.
        -- * Maximum X-axis coordinate.
        -- * Minimum Y-axis coordinate.
        -- * Maximum Y-axis coordinate.
        --
        getAABB = function(self) end,

        -- Gets the coordinate of the center of this node.
        --
        -- Args:
        -- * self: AbstractNode object.
        --
        -- Returns:
        -- * The X coordinate of the center.
        -- * The Y coordinate of the center.
        --
        getMiddle = function(self) end,

        -- Gets the minimum coordinate on the X axis (without margin).
        --
        -- Args:
        -- * self: AbstractNode object.
        --
        -- Returns: The minimum X-axis coordinate.
        --
        getXMin = function(self) end,

        -- Get the length of this node on the X axis.
        --
        -- Args:
        -- * self: AbstractNode object.
        -- * withMargins: True to include the xMargin.
        --
        -- Returns: The length of this object on the X axis.
        --
        getXLength = function(self, withMargins)  end,

        -- Get the length of this node on the Y axis.
        --
        -- Args:
        -- * self: AbstractNode object.
        -- * withMargins: True to include the yMargin.
        --
        -- Returns: The length of this object on the Y axis.
        --
        getYLength = function(self, withMargins) end,

        -- Sets the minimum coordinate on the X axis (margin NOT included).
        --
        -- Args:
        -- * self: AbstractNode object.
        -- * xMin: New xMin value.
        --
        setXMin = function(self, xMin) end,

        -- Sets the minimum coordinate on the Y axis (margin NOT included).
        --
        -- Args:
        -- * self: AbstractNode object.
        -- * yMin: New yMin value.
        --
        setYMin = function(self, yMin) end,

        -- Projects a point along the Y axis on the node.
        --
        -- Args:
        -- * self: AbstractNode object.
        -- * x: X coordinate of the point to project.
        -- * isFromLowY: True to project from -infinity on the Y axis. False from +infinity.
        --
        -- Returns: The Y coordinate of the projected point.
        --
        yProject = function(self, x, isFromLowY) end,
}

--]]

return AbstractNode
