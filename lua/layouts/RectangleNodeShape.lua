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
local RectangleNode = require("lua/layouts/RectangleNode")

local cLogger = ClassLogger.new{className = "RectangleNodeShape"}

local Metatable

-- Class holding data to build RectangleNode objects in a layout.
--
-- Fields:
-- * minXLength: Minimum desired X-length of nodes.
-- * minYLength: Minimum desired Y-length of nodes.
-- * xMargin: Space to leave around the node on the X-axis.
-- * yMargin: Space to leave around the node on the Y-axis.
--
local RectangleNodeShape = ErrorOnInvalidRead.new{
    -- Creates a new RectangleNodeShape object.
    --
    -- Args:
    -- * object: Table to turn into a RectangleNodeShape object.
    --
    -- Returns: The argument turned into a RectangleNodeShape object.
    --
    new = function(object)
        cLogger:assertField(object, "minXLength")
        cLogger:assertField(object, "minYLength")
        cLogger:assertField(object, "xMargin")
        cLogger:assertField(object, "yMargin")
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the RectangleNodeShape class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates a RectangleNode object.
        --
        -- Args:
        -- * self: RectangleNodeShape object.
        -- * minXLength: Additional constraint on the X-length.
        --
        -- Returns: The new RectangleNode object.
        --
        generateNode = function(self, minXLength)
            local xLength = math.max(minXLength, self.minXLength)
            return RectangleNode.new{
                xLength = xLength,
                xMargin = self.xMargin,
                yLength = self.minYLength,
                yMargin = self.yMargin,
            }
        end,
    },
}

return RectangleNodeShape
