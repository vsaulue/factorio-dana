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
local HalfCircleRectNode = require("lua/layouts/HalfCircleRectNode")

local cLogger = ClassLogger.new{className = "HalfCircleRectNodeShape"}

local Metatable

-- AbstractNodeShape specialisation that generates HalfCircleRectNode objects.
--
-- Fields:
-- * minRadius: Desired value for the radius (lower bound).
--
local HalfCircleRectNodeShape = ErrorOnInvalidRead.new{
    -- Creates a new HalfCircleRectNodeShape object.
    --
    -- Args:
    -- * object: Table to turn into a HalfCircleRectNodeShape object.
    --
    -- Returns: The argument turned into a HalfCircleRectNodeShape object.
    --
    new = function(object)
        cLogger:assertField(object, "minRadius")
        return AbstractNodeShape.new(object, Metatable)
    end,
}

-- Metatable of the HalfCircleRectNodeShape class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractNodeShape:generateNode().
        generateNode = function(self, minXLength)
            local radius = math.max(self.minRadius, minXLength/2)
            return HalfCircleRectNode.new{
                radius = radius,
                xMargin = self.xMargin,
                yMargin = self.yMargin,
            }
        end,
    },
}

return HalfCircleRectNodeShape
