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
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local FullGraphQuery = require("lua/query/FullGraphQuery")
local GuiElement = require("lua/gui/GuiElement")
local QueryEditorWindow = require("lua/apps/query/gui/QueryEditorWindow")
local QueryTemplates = require("lua/apps/query/QueryTemplates")

local cLogger = ClassLogger.new{className = "queryApp/TemplateSelectWindow"}

local FullGraphButton
local StepName
local TemplateSelectButton

-- A menu window with a button for each query template.
--
-- Inherits from AbstractStepWindow.
--
-- RO Fields:
-- * fullGraphButton: FullGraphButton object.
-- * templateButtons: Set of TemplateSelectButton owned by this window.
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
        AbstractStepWindow.new(object)

        object.frame = object.app.appController.appResources.rawPlayer.gui.center.add{
            type = "frame",
            direction = "vertical",
            caption = {"dana.apps.query.templateSelectWindow.title"},
        }

        local app = object.app

        local innerFrame = object.frame.add{
            type = "frame",
            style = "inside_deep_frame",
        }
        innerFrame.style.padding = 4
        local flow = innerFrame.add{
            type = "flow",
            direction = "vertical",
        }
        flow.style.vertical_spacing = 4
        object.fullGraphButton = FullGraphButton.new{
            app = app,
            rawElement = flow.add{
                type = "button",
                caption = {"dana.apps.query.templateSelectWindow.fullGraph"},
                style = "menu_button",
            },
        }
        object.templateButtons = ErrorOnInvalidRead.new()
        for templateName,template in pairs(QueryTemplates) do
            local newButton = TemplateSelectButton.new{
                app = app,
                rawElement = flow.add{
                    type = "button",
                    caption = template.caption,
                    style = "menu_button",
                },
                templateName = templateName,
            }
            object.templateButtons[newButton] = true
        end
        return object
    end,

    -- Restores the metatable of a TemplateSelectWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, AbstractStepWindow.Metatable)
        FullGraphButton.setmetatable(object.fullGraphButton)

        ErrorOnInvalidRead.setmetatable(object.templateButtons)
        for templateButton in pairs(object.templateButtons) do
            TemplateSelectButton.setmetatable(templateButton)
        end
    end,
}

-- Button to display the full recipe graph.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * app: QueryApp owning this button.
--
FullGraphButton = GuiElement.newSubclass{
    className = "queryApp/FullGraphButton",
    mandatoryFields = {"app"},
    __index = {
        onClick = function(self, event)
            self.app.query = FullGraphQuery.new()
            self.app:runQueryAndDraw()
        end,
    },
}

-- Unique name for this step.
StepName = "templateSelect"

-- Button to select a preset query template.
--
-- Inherits from GuiElement.
--
-- TO Fields:
-- * app: QueryApp owining this button.
-- * templateName: Name of the template to load from QueryTemplates.
--
TemplateSelectButton = GuiElement.newSubclass{
    className = "queryApp/TemplateSelectButton",
    mandatoryFields = {"app", "templateName"},
    __index = {
        onClick = function(self, event)
            local template = QueryTemplates[self.templateName]
            local app = self.app

            template.applyTemplate(app)
            app:pushStepWindow(QueryEditorWindow.new{
                app = app,
            })
        end,
    },
}

AbstractStepWindow.Factory:registerClass(StepName, TemplateSelectWindow)
return TemplateSelectWindow
