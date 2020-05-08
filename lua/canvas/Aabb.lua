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

local cLogger = ClassLogger.new{className = "Aabb"}

-- Class representing an Axis Aligned Bounding Box (-> AABB).
--
-- Fields:
-- * xMax: Maximum value on the X axis.
-- * xMin: Minimum value on the X axis.
-- * yMax: Maximum value on the Y axis.
-- * yMin: Minimum value on the Y axis.
--
local Aabb = ErrorOnInvalidRead.new{
    -- Creates a new Aabb object.
    new = function(object)
        local xMin = cLogger:assertField(object, "xMin")
        local xMax = cLogger:assertField(object, "xMax")
        cLogger:assert(xMin <= xMax, "invalid values (xMin > xMax).")
        local yMin = cLogger:assertField(object, "yMin")
        local yMax = cLogger:assertField(object, "yMax")
        cLogger:assert(yMin <= yMax, "invalid values (yMin > yMax).")

        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,
}

return Aabb
