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
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local QueryTemplates = require("lua/apps/query/QueryTemplates")

local cLogger = ClassLogger.new{className = "GuiTemplateSelectWindow"}

local FullGraphButton
local Metatable
local TemplateSelectButton

-- Instanciated GUI of an TemplateSelectWindow.
--
-- RO Fields:
-- * controller: TemplateSelectWindow. Owner of this GUI.
-- * frame: LuaGuiElement. Top-level frame owned by this GUI.
-- * fullGraphButton: FullGraphButton. Button owned by this GUI.
-- * parent: LuaGuiElement. Element containing this GUI.
-- * templateButtons[string]: TemplateSelectButton. Template selection button, indexed by template name.
--
local GuiTemplateSelectWindow = ErrorOnInvalidRead.new{
    -- Creates a new GuiTemplateSelectWindow object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiTemplateSelectWindow. The argument turned into the desired type.
    --
    new = function(object)
        local controller = cLogger:assertField(object, "controller")
        local parent = cLogger:assertField(object, "parent")

        object.frame = parent.add{
            type = "frame",
            direction = "vertical",
            caption = {"dana.apps.query.templateSelectWindow.title"},
        }
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
            controller = controller,
            rawElement = flow.add{
                type = "button",
                caption = {"dana.apps.query.templateSelectWindow.fullGraph"},
                style = "menu_button",
            },
        }
        object.templateButtons = ErrorOnInvalidRead.new()
        for templateName,template in pairs(QueryTemplates) do
            local newButton = TemplateSelectButton.new{
                controller = controller,
                rawElement = flow.add{
                    type = "button",
                    caption = template.caption,
                    style = "menu_button",
                },
                templateName = templateName,
            }
            object.templateButtons[templateName] = newButton
        end

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a GuiTemplateSelectWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        FullGraphButton.setmetatable(object.fullGraphButton)
        ErrorOnInvalidRead.setmetatable(object.templateButtons, nil, TemplateSelectButton.setmetatable)
    end,
}

-- Metatable of the GuiTemplateSelectWindow class.
Metatable = {
    __index = {
        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.fullGraphButton:close()
            Closeable.closeMapValues(self.templateButtons)
        end,
    }
}

-- Button to display the full recipe graph.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * controller: templateSelectWindow. Owner of this GUI.
--
FullGraphButton = GuiElement.newSubclass{
    className = "queryApp/FullGraphButton",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller:selectFullGraph()
        end,
    },
}

-- Button to select a preset query template.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * controller: templateSelectWindow. Owner of this GUI.
-- * templateName: Name of the template to load from QueryTemplates.
--
TemplateSelectButton = GuiElement.newSubclass{
    className = "queryApp/TemplateSelectButton",
    mandatoryFields = {"controller", "templateName"},
    __index = {
        onClick = function(self, event)
            self.controller:selectTemplate(self.templateName)
        end,
    },
}

return GuiTemplateSelectWindow
