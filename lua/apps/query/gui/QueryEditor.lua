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

local AbstractFilterEditor = require("lua/apps/query/gui/AbstractFilterEditor")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")

local cLogger = ClassLogger.new{className = "QueryEditor"}

local BackButton
local DrawButton
local Metatable

-- GUI Window to edit a the query of a QueryApp.
--
-- RO Fields:
-- * app: QueryApp object owning this window.
-- * backButton: BackButton object of this window.
-- * drawButton: DrawButton of this window.
-- * filterEditor: AbstractFilterEditor of this window.
-- * filterEditorRoot: LuaGuiElement used as root of the filter editor.
-- * frame: Frame object from Factorio (LuaGuiElement).
--
local QueryEditor = ErrorOnInvalidRead.new{
    -- Creates a new QueryEditor object.
    --
    -- Args:
    -- * object: Table to turn into a QueryEditor object (required field: app).
    --
    -- Returns: The argument turned into a QueryEditor object.
    --
    new = function(object)
        local app = cLogger:assertField(object, "app")
        setmetatable(object, Metatable)
        object.frame = app.appController.appResources.rawPlayer.gui.center.add{
            type = "frame",
            direction = "vertical",
            caption = {"dana.apps.query.queryEditor.title"},
        }
        local innerFrame = object.frame.add{
            type = "frame",
            style = "inside_shallow_frame",
            direction = "vertical",
        }
        object.filterEditorRoot = innerFrame.add{
            type = "flow",
            direction = "vertical",
        }
        local bottomFlow = object.frame.add{
            type = "flow",
            direction = "horizontal",
        }
        object.backButton = BackButton.new{
            app = app,
            rawElement = bottomFlow.add{
                type = "button",
                caption = {"gui.cancel"},
                style = "back_button",
            },
        }
        local pusher = bottomFlow.add{
            type = "empty-widget",
            style = "draggable_space_with_no_left_margin",
        }
        pusher.style.horizontally_stretchable = true
        object.drawButton = DrawButton.new{
            app = app,
            rawElement = bottomFlow.add{
                type = "button",
                caption = {"dana.apps.query.queryEditor.draw"},
                style = "confirm_button",
            },
        }
        return object
    end,

    -- Restores the metatable of a QueryEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        BackButton.setmetatable(object.backButton)
        DrawButton.setmetatable(object.drawButton)
        if object.filterEditor then
            AbstractFilterEditor.Factory:restoreMetatable(object.filterEditor)
        end
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the QueryEditor class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Changes the filter editor of this object.
        --
        -- Args:
        -- * self: QueryEditor object.
        -- * filterEditorClass: Table of the class of the new filter AbstractFilterEditor.
        --
        changeFilterEditor = function(self, filterEditorClass)
            GuiElement.clear(self.filterEditorRoot)
            self.filterEditor = filterEditorClass.new{
                appResources = self.app.appController.appResources,
                filter = self.app.query.filter,
                root = self.filterEditorRoot,
            }
        end,

        -- Releases all API resources of this object.
        --
        -- Args:
        -- * self: QueryEditor object.
        --
        close = function(self)
            GuiElement.destroy(self.frame)
        end,
    },
}

-- Button to go back to the TemplateSelectWindow.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * app: QueryApp owning this button.
--
BackButton = GuiElement.newSubclass{
    className = "QueryEditor/BackButton",
    mandatoryFields = {"app"},
    __index = {
        onClick = function(self, event)
            self.app:returnToTemplateSelect()
        end,
    },
}

-- Button to run the query and render the generated graph.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * app: QueryApp owning this button.
--
DrawButton = GuiElement.newSubclass{
    className = "QueryEditor/DrawButton",
    mandatoryFields = {"app"},
    __index = {
        onClick = function(self, event)
            self.app:runQueryAndDraw()
        end,
    },
}

return QueryEditor
