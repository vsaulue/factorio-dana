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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "RectangleNode"}

local Metatable

-- Class holding the position data of a vertex/edge in a layout.
--
-- Fields:
-- * xLength: Length of this object on the X axis.
-- * xMin: Minimum coordinate on the X axis.
-- * xMargin: Margin on the X axis.
-- * yLength: Length of this object on the X axis.
-- * yMargin: Margin on the Y axis.
-- * yMin: Minimum coordinate on the Y axis.
--
local RectangleNode = ErrorOnInvalidRead.new{
    -- Creates a new RectangleNode object.
    --
    -- Args:
    -- * object: Table to turn into a RectangleNode object.
    --
    -- Returns: The argument turned into a RectangleNode object.
    --
    new = function(object)
        cLogger:assertField(object, "xLength")
        cLogger:assertField(object, "xMargin")
        cLogger:assertField(object, "yLength")
        cLogger:assertField(object, "yMargin")
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a RectangleNode instance, and all its owned objects.
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the RectangleNode class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets the 4 coordinates of the bounding box of this node (without margins).
        --
        -- Args:
        -- * self: RectangleNode object.
        --
        -- Returns:
        -- * Minimum X-axis coordinate.
        -- * Maximum X-axis coordinate.
        -- * Minimum Y-axis coordinate.
        -- * Maximum Y-axis coordinate.
        --
        getAABB = function(self)
            local xMin = self.xMin
            local yMin = self.yMin
            return xMin, xMin + self.xLength, yMin, yMin + self.yLength
        end,

        -- Gets the minimum coordinate on the X axis (without margin).
        --
        -- Args:
        -- * self: RectangleNode object.
        --
        -- Returns: The minimum X-axis coordinate.
        --
        getXMin = function(self)
            return self.xMin
        end,

        -- Get the length of this node on the X axis.
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * withMargins: True to include the xMargin.
        --
        -- Returns: The length of this object on the X axis.
        --
        getXLength = function(self, withMargins)
            local result = self.xLength
            if withMargins then
                result = result + 2 * self.xMargin
            end
            return result
        end,

        -- Get the length of this node on the Y axis.
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * withMargins: True to include the yMargin.
        --
        -- Returns: The length of this object on the Y axis.
        --
        getYLength = function(self, withMargins)
            local result = self.yLength
            if withMargins then
                result = result + 2 * self.yMargin
            end
            return result
        end,

        -- Sets the minimum coordinate on the X axis (margin NOT included).
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * xMin: New xMin value.
        --
        setXMin = function(self, xMin)
            self.xMin = xMin
        end,

        -- Sets the minimum coordinate on the Y axis (margin NOT included).
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * yMin: New yMin value.
        --
        setYMin = function(self, yMin)
            self.yMin = yMin
        end,

        -- Projects a point along the Y axis on the rectangle.
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * x: X coordinate of the point to project.
        -- * isFromLowY: True to project from -infinity on the Y axis. False from +infinity.
        --
        -- Returns: The Y coordinate of the projected point.
        --
        yProject = function(self, x, isFromLowY)
            local result = self.yMin
            if not isFromLowY then
                result = result + self.yLength
            end
            return result
        end,
    },
}

return RectangleNode
