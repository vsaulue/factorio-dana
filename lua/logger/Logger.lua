-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local StdoutLoggerBackend = require("lua/logger/backends/StdoutLoggerBackend")

local backend
local checkField
local logInfoMsg

-- Static class providing a set of function to log messages.
--
-- This logger can either run inside Factorio or in standalone mode. This behaviour is
-- controlled by passing the appropriate LoggerBackend object to the Logger.init() function.
--
-- Subtype:
-- * LoggerBackend:
-- ** logToFile: Function to log a message into the file.
-- ** logToUsers: Function to display a message to user(s).
-- ** makeFullMessage: Function to generate a complete message in the log (the backend can prefix/reformat).
-- ** name: Name of this backend.
--
-- Static functions: see table content.
--
local Logger = {
    -- Logs an info message.
    --
    -- An info message for log files. To be used sparingly to avoid cluttering the production log.
    --
    -- Args:
    -- * message: Message to log.
    --
    info = function(message)
        local fullMsg = backend.makeFullMessage("[Info] " .. message)
        backend.logToFile(fullMsg)
    end,

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
    error = function(message)
        local fullMsg = backend.makeFullMessage("[Error] " .. message)
        error(fullMsg)
    end,

    -- Initialize the logger with the specified backend.
    --
    -- Args:
    -- * newBackend: LoggerBackend object to use.
    --
    init = function(newBackend)
        checkField(newBackend, "logToFile")
        checkField(newBackend, "logToUsers")
        checkField(newBackend, "makeFullMessage")
        checkField(newBackend, "name")
        backend = newBackend
        logInfoMsg("Logger started with the '" .. newBackend.name .. "' backend.")
    end,

    -- Logs a warning message.
    --
    -- A warning message is raised when the mod reads data from Factorio that looks wrong. The mod will try to recover
    -- from this state (by making guesses, or ignoring the data).
    --
    -- Args:
    -- * message: Message to log.
    --
    warn = function(message)
        local fullMsg = backend.makeFullMessage("[Warning] " .. message)
        backend.logToUsers(fullMsg)
        backend.logToFile(fullMsg)
    end,
}

-- Checks that
checkField = function(object, fieldName)
    if not object[fieldName] then
        error("Logger: missing field '" .. fieldName .. "' in backend implementation.")
    end
end

logInfoMsg = Logger.info

-- Default backend.
Logger.init(StdoutLoggerBackend)

return Logger
