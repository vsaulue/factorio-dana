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

local cLogger = ClassLogger.new{className = "RectangleNode"}

local Metatable
local NodeShapeType

-- AbstractNode specialisation for rectangle-shaped nodes.
--
-- Inherits from AbstractNode.
--
-- Fields:
-- * xLength: Length of this object on the X axis.
-- * xMin: Minimum coordinate on the X axis.
-- * yLength: Length of this object on the X axis.
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
        cLogger:assertField(object, "yLength")
        object.type = NodeShapeType
        return AbstractNode.new(object, Metatable)
    end,

    -- Restores the metatable of a RectangleNode instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the RectangleNode class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractNode:drawOnCanvas().
        drawOnCanvas = function(self, canvas, rendererArgs)
            local left_top = TableUtils.getOrInitTableField(rendererArgs, "left_top")
            left_top.x = self.xMin
            left_top.y = self.yMin
            local right_bottom = TableUtils.getOrInitTableField(rendererArgs, "right_bottom")
            right_bottom.x = self.xMin + self.xLength
            right_bottom.y = self.yMin + self.yLength

            return {
                [canvas:newRectangle(rendererArgs)] = true,
            }
        end,

        -- Implements AbstractNode:getAABB().
        getAABB = function(self)
            local xMin = self.xMin
            local yMin = self.yMin
            return xMin, xMin + self.xLength, yMin, yMin + self.yLength
        end,

        -- Implements AbstractNode:getMiddle()
        getMiddle = function(self)
            return self.xMin + self.xLength / 2, self.yMin + self.yLength / 2
        end,

        -- Implements AbstractNode:getXMin().
        getXMin = function(self)
            return self.xMin
        end,

        -- Implements AbstractNode:getXLength().
        getXLength = function(self, withMargins)
            local result = self.xLength
            if withMargins then
                result = result + 2 * self.xMargin
            end
            return result
        end,

        -- Implements AbstractNode:getYLength().
        getYLength = function(self, withMargins)
            local result = self.yLength
            if withMargins then
                result = result + 2 * self.yMargin
            end
            return result
        end,

        -- Implements AbstractNode:setXMin().
        setXMin = function(self, xMin)
            self.xMin = xMin
        end,

        -- Implements AbstractNode:setYMin().
        setYMin = function(self, yMin)
            self.yMin = yMin
        end,

        -- Implements AbstractNode:yProject().
        yProject = function(self, x, isFromLowY)
            local result = self.yMin
            if not isFromLowY then
                result = result + self.yLength
            end
            return result
        end,
    },
}

-- Unique name for this AbstractNode subtype.
NodeShapeType = "rectangle"

AbstractNode.Factory:registerClass(NodeShapeType, RectangleNode)
return RectangleNode
