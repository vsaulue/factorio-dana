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

local cLogger = ClassLogger.new{className = "GuiQueryEditor"}

local BackButton
local DrawButton
local Metatable

-- Instanciated GUI of an IntermediateSetEditor.
--
-- RO Fields:
-- * controller: AbstractQueryEditor. Owner of this GUI.
-- * frame: LuaGuiElement. Top-level element containing this GUI.
-- * paramsFrame: LuaGuiElement. Frame containing the paramsEditor GUI.
-- * parent: LuaGuiElement. Element containing this GUI.
--
local GuiQueryEditor = ErrorOnInvalidRead.new{
    -- Creates a new GuiQueryEditor object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiQueryEditor. `object` turned into the desired type.
    --
    new = function(object)
        local controller = cLogger:assertField(object, "controller")
        local parent = cLogger:assertField(object, "parent")

        object.frame = parent.add{
            type = "frame",
            direction = "vertical",
            caption = {"dana.apps.query.queryEditor.title"},
        }
        object.paramsFrame = object.frame.add{
            type = "frame",
            style = "inside_shallow_frame_with_padding",
            direction = "vertical",
        }

        local bottomFlow = object.frame.add{
            type = "flow",
            direction = "horizontal",
        }
        object.backButton = BackButton.new{
            controller = controller,
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
            controller = controller,
            rawElement = bottomFlow.add{
                type = "button",
                caption = {"dana.apps.query.queryEditor.draw"},
                style = "confirm_button",
            },
        }

        setmetatable(object, Metatable)
        object:updateParamsEditor()
        return object
    end,

    -- Restores the metatable of an GuiQueryEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        BackButton.setmetatable(object.backButton)
        DrawButton.setmetatable(object.drawButton)
    end,
}

-- Metatable of the GuiQueryEditor class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.backButton:close()
            self.drawButton:close()
        end,

        -- Updates this GUI to use the current "paramsEditor" of the controller.
        --
        -- Args:
        -- * self: GuiQueryEditor.
        --
        updateParamsEditor = function(self)
            local paramsEditor = rawget(self.controller, "paramsEditor")
            if paramsEditor then
                paramsEditor:open(self.paramsFrame)
            end
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
    className = "QueryEditorWindow/BackButton",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller.appInterface:popStepWindow()
        end,
    },
}

-- Button to run the query and render the generated graph.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * controller: QueryApp owning this button.
--
DrawButton = GuiElement.newSubclass{
    className = "QueryEditorWindow/DrawButton",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller:runQueryAndDraw()
        end,
    },
}

return GuiQueryEditor
