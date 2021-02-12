-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local AbstractGui = require("lua/gui/AbstractGui")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")

local BackButton
local DrawButton
local GuiConstructorArgs
local Metatable

-- Instanciated GUI of an IntermediateSetEditor.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * backButton: BackButton. Bottom-left back button.
-- * drawButton: DrawButton. Bottom-right button to draw the graph.
-- * controller (override): AbstractQueryEditor.
-- * frame: LuaGuiElement. Top-level element containing this GUI.
-- + AbstractGui.
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
        AbstractGui.new(object, Metatable)
        local controller = object.controller

        object.frame = GuiMaker.run(object.parent, GuiConstructorArgs)
        object.backButton = BackButton.new{
            controller = controller,
            rawElement = object.frame.footer.backButton,
        }
        object.drawButton = DrawButton.new{
            controller = controller,
            rawElement = object.frame.footer.drawButton,
        }
        controller.menu:open(object.frame.content.menu)

        if object.frame.location then
            object.frame.force_auto_center()
        end

        object:updateParamsEditor()
        return object
    end,

    -- Restores the metatable of an GuiQueryEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        BackButton.setmetatable(object.backButton)
        DrawButton.setmetatable(object.drawButton)
    end,
}

-- Metatable of the GuiQueryEditor class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.backButton:close()
            self.drawButton:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.frame.valid
        end,

        -- Updates this GUI to use the current "paramsEditor" of the controller.
        --
        -- Args:
        -- * self: GuiQueryEditor.
        --
        updateParamsEditor = function(self)
            if self:sanityCheck() then
                local paramsEditor = rawget(self.controller, "paramsEditor")
                if paramsEditor then
                    paramsEditor:open(self.frame.content.params)
                end
            end
        end,
    },
})

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

-- GuiMaker's arguments to build this GUI.
GuiConstructorArgs = {
    type = "frame",
    direction = "vertical",
    caption = {"dana.apps.query.queryEditor.title"},
    children = {
        {
            type = "flow",
            direction = "horizontal",
            name = "content",
            children = {
                {
                    type = "frame",
                    direction = "vertical",
                    name = "menu",
                    style = "inside_deep_frame",
                    styleModifiers = {
                        vertically_stretchable = true,
                        minimal_width = 150,
                        padding = 2,
                    },
                },{
                    type = "frame",
                    style = "inside_shallow_frame_with_padding",
                    direction = "vertical",
                    name = "params",
                },
            },
        },{
            type = "flow",
            direction = "horizontal",
            name = "footer",
            children = {
                {
                    type = "button",
                    caption = {"gui.cancel"},
                    style = "back_button",
                    name = "backButton",
                },{
                    type = "empty-widget",
                    styleModifiers = {
                        horizontally_stretchable = true,
                    },
                },{
                    type = "button",
                    caption = {"dana.apps.query.queryEditor.draw"},
                    style = "confirm_button",
                    name = "drawButton",
                },
            },
            styleModifiers = {
                top_margin = 4,
            },
        },
    },
}

return GuiQueryEditor
