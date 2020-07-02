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
local QueryEditor = require("lua/apps/query/gui/QueryEditor")
local TemplateSelectWindow = require("lua/apps/query/gui/TemplateSelectWindow")

local AppName
local Metatable

-- Application to build crafting hypergraphs from a Force's database.
--
-- Inherits from AbstractApp.
--
-- RO Fields:
-- * isTemplateSelected: boolean indicating if the TemplateSelectWindow is currently opened.
-- * query: Query object being built and run.
-- * queryEditor: QueryEditor object used to edit the query of this object.
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

        object.isTemplateSelected = false
        object.queryEditor = QueryEditor.new{
            app = object,
        }
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
        QueryEditor.setmetatable(object.queryEditor)
    end,
}

-- Metatable of the QueryApp class.
Metatable = {
    __index = {
        -- Implements AbstractApp:close().
        close = function(self)
            self.queryEditor:close()
            self.templateSelectWindow:close()
        end,

        -- Implements AbstractApp:hide().
        hide = function(self)
            self.templateSelectWindow.frame.visible = false
            self.queryEditor.frame.visible = false
        end,

        -- Runs the query, and switch to the Graph app.
        --
        -- Args:
        -- * self: QueryApp object.
        --
        runQueryAndDraw = function(self)
            local query = self.query
            local force = self.appController.appResources.force
            local graph,vertexDists = query:execute(force)
            self.appController:makeAndSwitchApp{
                appName = "graph",
                graph = graph,
                vertexDists = vertexDists,
            }
        end,

        -- Hides the QueryEditor window, and reopen the TemplateSelectWindow.
        --
        -- Args:
        -- * self: QueryApp object.
        --
        returnToTemplateSelect = function(self)
            self.isTemplateSelected = false
            self.templateSelectWindow.frame.visible = true
            self.queryEditor.frame.visible = false
        end,

        -- Loads a preset query, and opens the QueryEditor.
        --
        -- Args:
        -- * self: QueryApp object.
        -- * queryTemplate: QueryTemplate object, used to generate the preset query.
        --
        selectTemplate = function(self, queryTemplate)
            queryTemplate.applyTemplate(self)

            self.isTemplateSelected = true
            self.templateSelectWindow.frame.visible = false
            self.queryEditor.frame.visible = true
        end,

        -- Implements AbstractApp:show().
        show = function(self)
            if self.isTemplateSelected then
                self.queryEditor.frame.visible = true
            else
                self.templateSelectWindow.frame.visible = true
            end
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractApp.Metatable.__index})

-- Unique name for this application.
AppName = "query"

AbstractApp.Factory:registerClass(AppName, QueryApp)
return QueryApp
