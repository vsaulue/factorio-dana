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

local Prefix

-- LoggerBackend object to use inside Factorio.
--
-- See Logger subtypes for field meaning.
--
local FactorioLoggerBackend = {
    logToFile = log,

    logToUsers = function(...)
        game.print(...)
    end,

    makeFullMessage = function(msg)
        return Prefix .. msg
    end,

    name = "Factorio",
}

Prefix = "[" .. script.mod_name .. "]"

return FactorioLoggerBackend
