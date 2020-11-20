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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "QueryAppInterface"}

local checkMethods

-- Interface containing callbacks from top-level controller of the query application.
--
-- RO Fields:
-- * appResources: AppResources. Resources available to this application.
--
local QueryAppInterface = ErrorOnInvalidRead.new{
    -- Checks all methods & fields.
    --
    -- Args:
    -- * object: QueryAppInterface.
    --
    check = function(object)
        cLogger:assertField(object, "appResources")
        checkMethods(object)
    end,

    -- Checks that all methods are implemented.
    --
    -- Args:
    -- * object: QueryAppInterface.
    --
    checkMethods = function(object)
        cLogger:assertField(object, "popStepWindow")
        cLogger:assertField(object, "pushStepWindow")
        cLogger:assertField(object, "runQueryAndDraw")
    end,
}

--[[
Metatable = {
    __index = {
        -- Closes the top window, and shows the previous one.
        --
        -- Args:
        -- * self: QueryAppInterface.
        --
        popStepWindow = function(self) end,

        -- Hides the current window, and shows a new one.
        --
        -- Args:
        -- * self: QueryAppInterface object.
        --
        pushStepWindow = function(self, newWindow) end,

        -- Runs the query, and switch to the Graph app.
        --
        -- Args:
        -- * self: QueryAppInterface object.
        -- * query: AbstractQuery. Query to execute.
        --
        runQueryAndDraw = function(self, query) end,
    },
}
--]]

checkMethods = QueryAppInterface.checkMethods

return QueryAppInterface
