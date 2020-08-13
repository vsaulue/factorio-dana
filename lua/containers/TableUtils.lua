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

-- Utility library for table manipulation.
--
local TableUtils = ErrorOnInvalidRead.new{
    -- Gets a field in an object (initialises it as an empty table if not set).
    --
    -- Args:
    -- * container: Object containing the field to get/set.
    -- * fieldName: Index of the field to get/set.
    --
    -- Returns: The value of the specified field.
    --
    getOrInitTableField = function(container, fieldName)
        local result = container[fieldName]
        if not result then
            result = {}
            container[fieldName] = result
        end
        return result
    end,
}

return TableUtils
