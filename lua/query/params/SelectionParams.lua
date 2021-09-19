-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

-- Parameters to select the input intermediates & transforms of a query.
--
-- Fields:
-- * enableBoilers: boolean. Include "boiler" type transforms.
-- * enableFuels: boolean. Include "fuel" type transforms.
-- * enableRecipes: boolean. Include "recipe" type transforms.

local SelectionParams = ErrorOnInvalidRead.new{
    -- Creates a new SelectionParams object.
    --
    -- Args:
    -- * object: table | nil. Table to turn into a SelectionParams object.
    --
    -- Returns: SelectionParams. The `object` argument if not nil.
    --
    new = function(object)
        local result = object
        if not object then
            result = {
                enableBoilers = true,
                enableFuels = true,
                enableRecipes = true,
            }
        else
            result.enableBoilers = not not result.enableBoilers
            result.enableFuels = not not result.enableFuels
            result.enableRecipes = not not result.enableRecipes
        end
        return setmetatable(result, Metatable)
    end,

    -- Restores the metatable of a SelectionParams object, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the SelectionParams class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Creates a copy of this object.
        --
        -- Args:
        -- * self: SelectionParams.
        --
        -- Returns: SelectionParams. A copy of `self`.
        --
        newCopy = function(self)
            return SelectionParams.new{
                enableBoilers = self.enableBoilers,
                enableFuels = self.enableFuels,
                enableRecipes = self.enableRecipes,
            }
        end,
    },
}

return SelectionParams
