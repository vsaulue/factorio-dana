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

local Metatable

-- Base class for types that are not copied by the SaveLoadTester.
--
local AutoLoaded = {
    -- Creates a new AutoLoaded object.
    --
    -- Args:
    -- * object: table.
    --
    -- Returns: AutoLoaded. The `object` argument turned into the desired type.
    --
    new = function(object)
        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the AutoLoaded class.
Metatable = {
    autoLoaded = true,
}

return AutoLoaded
