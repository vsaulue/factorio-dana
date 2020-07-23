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

local Metatable

-- Class holding the position data of a vertex/edge in a layout.
--
-- Fields:
-- * xMin: Minimum coordinate on the X axis.
-- * xMax: Maximum coordinate on the X axis.
-- * xMargin: Margin on the X axis.
-- * yMin: Minimum coordinate on the Y axis.
-- * yMax: Maximum coordinate on the Y axis.
--
local RectangleNode = ErrorOnInvalidRead.new{
    -- Creates a new RectangleNode object.
    --
    -- Args:
    -- * object: Table to turn into a RectangleNode object.
    --
    -- Returns: The argument turned into a RectangleNode object.
    --
    new = function()
        local result = {}
        setmetatable(result, Metatable)
        return result
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
            return self.xMin, self.xMax, self.yMin, self.yMax
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
            local result = self.xMax - self.xMin
            if withMargins then
                result = result + 2 * self.xMargin
            end
            return result
        end,

        -- Initializes the X coordinates of this node.
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * xMin: New xMin value.
        -- * xLength: New length of this object on the X-axis.
        -- * xMargin: X margin of this object.
        --
        initX = function(self, xMin, xLength, xMargin)
            self.xMin = xMin
            self.xMax = xMin + xLength
            self.xMargin = xMargin
        end,

        -- Initializes the Y coordinates of this node.
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * yMin: New yMin value.
        -- * yMax: New yMax value.
        --
        initY = function(self, yMin, yMax)
            self.yMin = yMin
            self.yMax = yMax
        end,

        -- Moves this object on the X axis.
        --
        -- Args:
        -- * self: RectangleNode object.
        -- * xDelta: Value to add to the X coordinates.
        --
        translateX = function(self, xDelta)
            self.xMin = self.xMin + xDelta
            self.xMax = self.xMax + xDelta
        end,
    },
}

return RectangleNode