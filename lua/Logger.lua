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
    perfDebug = nil, -- implemented later
    warn = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Prefix for all messages.
    Prefix = "[" .. script.mod_name .. "] "
}

-- Logs a debug message.
--
-- A debug message is just a trace message to help the developers understand what's happening.
-- They should not be displayed anywhere in a "production" environment.
--
-- Args:
-- * message: Message to log.
--
function Logger.debug(message)
    game.print(Impl.Prefix .. "Debug: " .. message)
end

-- Logs an error message & and terminates the program.
--
-- An error message is raised when the mod is in an inconsistent state.
--
-- The mod is now in "undefined behaviour" mode, so the game is stopped to prevent
-- things from going worse.
--
-- Args:
-- * message: Message to log.
--
function Logger.error(message)
    local fullMsg = Impl.Prefix .. "Error: " .. message
    error(fullMsg)
end

-- Logs a performance debug message.
--
-- A performance debug message is a trace message to help the developers optimize the code.
-- They should not be displayed anywhere in a "production" environment.
--
function Logger.perfDebug(message)
    game.print(Impl.Prefix .. "Perf: " .. message)
    game.print(debug.traceback())
end

-- Logs a warning message.
--
-- A warning message is raised when the mod reads data from Factorio that looks wrong. The mod will try to recover
-- from this state (by making guesses, or ignoring the data).
--
-- Args:
-- * message: Message to log.
--
function Logger.warn(message)
    game.print(Impl.Prefix .. "Warning: " .. message)
end

return Logger
