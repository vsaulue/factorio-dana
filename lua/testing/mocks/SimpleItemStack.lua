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

local cLogger = ClassLogger.new{className = "SimpleItemStack"}

-- Mock of SimpleItemStack concept.
--
-- See https://lua-api.factorio.com/1.0.0/Concepts.html#SimpleItemStack
--
-- Implemented fields:
-- * count
-- * name
--
local SimpleItemStack = {
    -- Checks if a value is a correct SimpleItemStack.
    --
    -- Args:
    -- * object: table. Input arguments as described in the API.
    --
    -- Returns: SimpleItemStack. The `object` argument.
    --
    make = function(args)
        local name = cLogger:assertFieldType(args, "name", "string")

        local count = 1
        if args.count ~= nil then
            count = cLogger:assertFieldType(args, "count", "number")
            cLogger:assert(count > 0, "count must be stricly positive.")
        end

        return {
            name = name,
            count = count,
        }
    end,
}

return SimpleItemStack
