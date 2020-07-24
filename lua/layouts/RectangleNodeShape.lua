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

local AbstractNodeShape = require("lua/layouts/AbstractNodeShape")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local RectangleNode = require("lua/layouts/RectangleNode")

local cLogger = ClassLogger.new{className = "RectangleNodeShape"}

local Metatable

-- AbstractNodeShape specialisation that generates RectangleNode objects.
--
-- Fields:
-- * minXLength: Minimum desired X-length of nodes.
-- * minYLength: Minimum desired Y-length of nodes.
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
        return AbstractNodeShape.new(object, Metatable)
    end,
}

-- Metatable of the RectangleNodeShape class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractNodeShape:generateNode().
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
