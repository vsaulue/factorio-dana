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

local AbstractStepWindow = require("lua/apps/query/step/AbstractStepWindow")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local FullGraphQuery = require("lua/query/FullGraphQuery")
local GuiTemplateSelectWindow = require("lua/apps/query/step/GuiTemplateSelectWindow")
local QueryEditor = require("lua/apps/query/step/editor/QueryEditor")
local QueryTemplates = require("lua/apps/query/QueryTemplates")

local cLogger = ClassLogger.new{className = "queryApp/TemplateSelectWindow"}

local FullGraphButton
local Metatable
local StepName
local TemplateSelectButton

-- A menu window with a button for each query template.
--
-- Inherits from AbstractStepWindow.
--
local TemplateSelectWindow = ErrorOnInvalidRead.new{
    -- Creates a new TemplateSelectWindow object.
    --
    -- Args:
    -- * object: Table to turn into a TemplateSelectWindow object (required field: app).
    --
    -- Returns: The argument turned into a TemplateSelectWindow object.
    --
    new = function(object)
        object.stepName = StepName
        AbstractStepWindow.new(object, Metatable)
        return object
    end,

    -- Restores the metatable of a TemplateSelectWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractStepWindow.setmetatable(object, Metatable, GuiTemplateSelectWindow.setmetatable)
    end,
}

-- Metatable of the TemplateSelectWindow class.
Metatable = {
    __index = {
        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiTemplateSelectWindow.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Selects the "Full graph" query.
        --
        -- Args:
        -- * self: TemplateSelectWindow.
        --
        selectFullGraph = function(self)
            self.appInterface:runQueryAndDraw(FullGraphQuery.new())
        end,

        -- Selects a query template.
        --
        -- Args:
        -- * self: TemplateSelectWindow.
        -- * templateName: string. Name of the template in QueryTemplates.
        --
        selectTemplate = function(self, templateName)
            local template = QueryTemplates[templateName]
            local appInterface = self.appInterface

            appInterface:pushStepWindow(QueryEditor.new{
                appInterface = appInterface,
                query = template.queryClass.new(),
            })
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractStepWindow.Metatable.__index})

-- Unique name for this step.
StepName = "templateSelect"

AbstractStepWindow.Factory:registerClass(StepName, TemplateSelectWindow)
return TemplateSelectWindow
