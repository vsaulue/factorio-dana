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



-- Mock of LuaGuiElement.direction subtype.
--
-- See https://lua-api.factorio.com/1.0.0/LuaGuiElement.html#LuaGuiElement.direction.
--
local GuiDirection = {
    -- Checks if a value is a correct direction.
    --
    -- Args:
    -- * value: string. Value to check.
    --
    -- Returns: The input value.
    --
    check = function(value)
        assert(value == "horizontal" or value == "vertical", "Invalid direction: " .. tostring(value))
        return value
    end,
}

return GuiDirection
