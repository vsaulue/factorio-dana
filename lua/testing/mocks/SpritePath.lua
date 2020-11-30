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

local cLogger = ClassLogger.new{className = "SpritePath"}

-- Mock of SpritePath concept.
--
-- See https://lua-api.factorio.com/1.0.0/Concepts.html#SpritePath
--
local SpritePath = {
    -- Checks if a value is a correct SpritePath.
    --
    -- Args:
    -- * object: table. Input arguments as described in the API.
    --
    -- Returns: SpritePath. The `object` argument.
    --
    check = function(object)
        -- Note: all we can do for now, without prototype access...
        if type(object) ~= "string" then
            cLogger:error("Invalid sprite path (string required).")
        end
        return object
    end,
}

return SpritePath
