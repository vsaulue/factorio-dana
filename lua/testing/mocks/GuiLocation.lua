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

local cLogger = ClassLogger.new{className = "GuiLocation"}

-- Mock of LuaGuiElement.direction subtype.
--
-- See https://lua-api.factorio.com/1.0.0/Concepts.html#GuiLocation
--
local GuiLocation = {
    -- Fills a GuiLocation object with a given value.
    --
    -- Args:
    -- * object: GuiLocation.
    -- * value: table. Input to parse.
    --
    parse = function(object, value)
        local x = value.x
        local y
        if x then
            y = value.y
        else
            x = value[1]
            y = value[2]
        end

        local errorMsg = "Invalid GuiLocation: must contain ('x' and 'y') or (1 and 2) indices."
        cLogger:assert(type(x) == "number", errorMsg)
        cLogger:assert(type(y) == "number", errorMsg)

        object.x = math.floor(x)
        object.y = math.floor(y)
    end,
}

return GuiLocation
