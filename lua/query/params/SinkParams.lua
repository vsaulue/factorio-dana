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

local new

-- Query parameters for sinks filtering.
--
-- Fields:
-- * filterNormal: boolean. Enable filters of "normal" direct sinks.
-- * filterRecursive: boolean. Enable filters of "recursive" direct sinks.
-- * indirectThreshold: int. Threshold for indirect sink filtering (higher value = less transforms removed).
--
local SinkParams = ErrorOnInvalidRead.new{
    -- Copy constructor.
    --
    -- Args:
    -- * map: table. Same fields as a SinkParams object.
    --
    -- Returns: SinkParams. The new copy.
    --
    copy = function(data)
        return new{
            filterNormal = data.filterNormal,
            filterRecursive = data.filterRecursive,
            indirectThreshold = data.indirectThreshold,
        }
    end,

    -- Creates a new SinkParams object.
    --
    -- Args:
    -- * object: table or nil.
    --
    -- Returns: SinkParams. The `object` argument if not nil.
    --
    new = function(object)
        local result = object or {}
        result.filterNormal = not not result.filterNormal
        result.filterRecursive = not not result.filterRecursive
        result.indirectThreshold = result.indirectThreshold or 64
        ErrorOnInvalidRead.setmetatable(result)
        return result
    end,

    -- Restores the metatable of a SinkParams object.
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

new = SinkParams.new

return SinkParams
