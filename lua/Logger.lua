-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

-- Set of methods to log messages.
--
local Logger = {
    debug = nil, -- implemented later
    error = nil, -- implemented later
}

local Impl = {
    -- Prefix for all messages.
    Prefix = "[mymod] "
}

-- Logs a debug message.
function Logger.debug(message)
    game.print(Impl.Prefix .. "Debug: " .. message)
end

-- Logs an error message.
function Logger.error(message)
    game.print(Impl.Prefix .. "Error: " .. message)
    game.print(debug.traceback())
end

return Logger