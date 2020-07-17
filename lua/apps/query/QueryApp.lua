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

local AbstractStepWindow = require("lua/apps/query/gui/AbstractStepWindow")
local AbstractApp = require("lua/apps/AbstractApp")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Query = require("lua/model/query/Query")
local QueryEditor = require("lua/apps/query/gui/QueryEditor")
local Stack = require("lua/containers/Stack")
local TemplateSelectWindow = require("lua/apps/query/gui/TemplateSelectWindow")

local AppName
local Metatable
local setTopWindowVisible

-- Application to build crafting hypergraphs from a Force's database.
--
-- Inherits from AbstractApp.
--
-- RO Fields:
-- * query: Query object being built and run.
-- * stepWindows: Stack of AbstractStepWindow objects (the top one is the only active).
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

        object.stepWindows = Stack.new()
        object.stepWindows:push(TemplateSelectWindow.new{
            app = object,
        })

        return object
    end,

    -- Restores the metatable of a QueryApp object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        Query.setmetatable(object.query)

        local stack = object.stepWindows
        Stack.setmetatable(stack)
        for index=1,stack.topIndex do
            AbstractStepWindow.Factory:restoreMetatable(stack[index])
        end
    end,
}

-- Metatable of the QueryApp class.
Metatable = {
    __index = {
        -- Implements AbstractApp:close().
        close = function(self)
            local stack = self.stepWindows
            for index=stack.topIndex,1,-1 do
                stack[index]:close()
            end
        end,

        -- Implements AbstractApp:hide().
        hide = function(self)
            setTopWindowVisible(self, false)
        end,

        -- Closes the top window, and shows the previous one.
        --
        -- Args:
        -- * self: QueryApp object.
        --
        popStepWindow = function(self)
            local window = self.stepWindows:pop()
            window:close()
            setTopWindowVisible(self, true)
        end,

        -- Hides the current window, and shows a new one.
        --
        -- Args:
        -- * self: QueryApp object.
        --
        pushStepWindow = function(self, newWindow)
            setTopWindowVisible(self, false)
            self.stepWindows:push(newWindow)
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

        -- Loads a preset query, and opens the QueryEditor.
        --
        -- Args:
        -- * self: QueryApp object.
        -- * queryTemplate: QueryTemplate object, used to generate the preset query.
        --
        selectTemplate = function(self, queryTemplate)
            queryTemplate.applyTemplate(self)

            setTopWindowVisible(self, false)
            self.stepWindows:push(QueryEditor.new{
                app = self,
            })
        end,

        -- Implements AbstractApp:show().
        show = function(self)
            setTopWindowVisible(self, true)
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractApp.Metatable.__index})

-- Unique name for this application.
AppName = "query"

-- Shows (or hide) the frame of the AbstractStepWindow on top of the stack.
--
-- Args:
-- * self: QueryApp object.
-- * value: True for visible, false to hide.
--
setTopWindowVisible = function(self, value)
    local stack = self.stepWindows
    stack[stack.topIndex].frame.visible = value
end

AbstractApp.Factory:registerClass(AppName, QueryApp)
return QueryApp
