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

local cLogger = ClassLogger.new{className = "AbstractNodeShape"}

-- Class holding data to build AbstractNode objects in a layout.
--
-- Fields:
-- * xMargin: Space to leave around the node on the X-axis.
-- * yMargin: Space to leave around the node on the Y-axis.
--
local AbstractNodeShape = ErrorOnInvalidRead.new{
    -- Creates a new AbstractNodeShape object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractNodeShape object.
    -- * metatable: Metatable to set.
    --
    -- Returns: The argument turned into an AbstractNodeShape object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "xMargin")
        cLogger:assertField(object, "yMargin")
        setmetatable(object, metatable)
        return object
    end,
}

--[[

Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates an AbstractNode object.
        --
        -- Args:
        -- * self: AbstractNodeShape object.
        -- * minXLength: Additional constraint on the X-length.
        --
        -- Returns: The new AbstractNode object.
        --
        generateNode = function(self, minXLength) end,
    },
}

--]]

return AbstractNodeShape
