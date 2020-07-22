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
    new = ErrorOnInvalidRead.new,

    -- Restores the metatable of a RectangleNode instance, and all its owned objects.
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

return RectangleNode
