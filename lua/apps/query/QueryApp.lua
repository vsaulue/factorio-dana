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

local AbstractApp = require("lua/apps/AbstractApp")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Query = require("lua/model/query/Query")
local TemplateSelectWindow = require("lua/apps/query/gui/TemplateSelectWindow")

local AppName
local Metatable

-- Application to build crafting hypergraphs from a Force's database.
--
-- Inherits from AbstractApp.
--
-- RO Fields:
-- * query: Query object being built and run.
-- * templateSelectWindow: TemplateSelectWindow object of this application.
--
local QueryApp = ErrorOnInvalidRead.new{
    -- Creates a new QueryApp object.
    --
    -- Args:
    -- * object: Table to turn into a QueryApp object.
    --
    -- Returns: The argument turned into a QueryApp object.
    --
    new = function(object)
        object.appName = AppName
        object.query = Query.new()

        AbstractApp.new(object, Metatable)

        object.templateSelectWindow = TemplateSelectWindow.new{
            app = object,
        }

        return object
    end,

    -- Restores the metatable of a QueryApp object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        TemplateSelectWindow.setmetatable(object.templateSelectWindow)
        Query.setmetatable(object.query)
    end,
}

-- Metatable of the QueryApp class.
Metatable = {
    __index = {
        -- Implements AbstractApp:close().
        close = function(self)
            self.templateSelectWindow:close()
        end,

        -- Implements AbstractApp:hide().
        hide = function(self)
            self.templateSelectWindow.frame.visible = false
        end,

        -- Implements AbstractApp:show().
        show = function(self)
            self.templateSelectWindow.frame.visible = true
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractApp.Metatable.__index})

-- Unique name for this application.
AppName = "query"

AbstractApp.Factory:registerClass(AppName, QueryApp)
return QueryApp
