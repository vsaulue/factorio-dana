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
local GuiElement = require("lua/gui/GuiElement")

local cLogger = ClassLogger.new{className = "queryApp/TemplateSelectWindow"}


local FullGraphButton
local Metatable

-- A menu window with a button for each query template.
--
-- RO Fields:
-- * app: QueryApp owning this window.
-- * frame: Frame object from Factorio (LuaGuiElement).
-- * fullGraphButton: FullGraphButton object.
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
        local app = cLogger:assertField(object, "app")
        object.frame = app.appController.appResources.rawPlayer.gui.center.add{
            type = "frame",
            caption = {"dana.apps.query.templateSelectWindow.title"},
            direction = "vertical",
        }
        object.fullGraphButton = FullGraphButton.new{
            app = app,
            rawElement = object.frame.add{
                type = "button",
                caption = {"dana.apps.query.templateSelectWindow.fullGraph"},
            },
        }
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a TemplateSelectWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        FullGraphButton.setmetatable(object.fullGraphButton)
    end,
}

-- Metatable of the TemplateSelectWindow class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Releases all API resources of this object.
        --
        -- Args:
        -- * self: TemplateSelectWindow object.
        --
        close = function(self)
            GuiElement.destroy(self.frame)
        end,
    }
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
            local query = self.app.query
            local force = self.app.appController.appResources.force
            local graph,vertexDists = query:execute(force)
            self.app.appController:makeAndSwitchApp{
                appName = "graph",
                graph = graph,
                vertexDists = vertexDists,
            }
        end,
    },
}

return TemplateSelectWindow
