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

local AbstractGui = require("lua/gui/AbstractGui")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "AbstractGuiSelectionPanel"}

local GuiConstructorArgs
local SelectionCategoryLabel

-- Instanciated GUI of an AbstractSelectionPanel.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller (override): GraphMenuFlow.
-- * mainFlow: LuaGuiElement. Top-level element owned by this GUI.
-- * titleLabel: SelectionCategoryLabel. Title label of this GUI.
-- + AbstractGui.
--
local AbstractGuiSelectionPanel = ErrorOnInvalidRead.new{
    -- Metatable of the AbstractGuiSelectionPanel class.
    Metatable = {
        __index = {
            -- Implements AbstractGui:close().
            close = function(self)
                GuiElement.safeDestroy(self.mainFlow)
                self.titleLabel:close()
            end,

            -- Implements AbstractGui:isValid().
            isValid = function(self)
                return self.mainFlow.valid
            end,

            -- Creates a GUI for a specific element.
            --
            -- NOT a method.
            --
            -- Args:
            -- * parent: LuaGuiElement. Where the GUI will be created.
            -- * key: any. Index from `self.controller.elements`.
            -- * value: any. Value from `self.controller.elements`, associated to `index`.
            --[[
            makeElementGui = function(parent, key, value) end,
            --]]

            -- LocalisedString. Caption of the title label.
            --[[
            Title = LocalisedString.new(),
            --]]

            -- Handles modifications of the controller's `element` field.
            --
            -- Args:
            -- * self: AbstractGuiSelectionPanel.
            --
            updateElements = function(self)
                local contentPane = self.mainFlow.content
                contentPane.clear()
                local elements = rawget(self.controller, "elements")
                local hasElements = elements and next(elements)
                self.mainFlow.visible = hasElements
                if hasElements then
                    local makeElementGui = self.makeElementGui
                    for key,value in pairs(elements) do
                        makeElementGui(contentPane, key, value)
                    end
                end
            end,

            -- Handles modifications of the controller's `expanded` field.
            --
            -- Args:
            -- * self: AbstractGuiSelectionPanel.
            --
            updateExpanded = function(self)
                local expanded = self.controller.expanded
                local titlePrefix
                if expanded then
                    titlePrefix = "▼ "
                else
                    titlePrefix = "▶ "
                end
                self.mainFlow.title.caption = {"", titlePrefix, self.Title}
                self.mainFlow.content.visible = expanded
            end,
        },
    },

    -- Creates a new AbstractGuiSelectionPanel object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: AbstractGuiSelectionPanel. The `object` argument turned into the desired type.
    --
    new = function(object, metatable)
        AbstractGui.new(object, metatable)
        cLogger:assertField(object, "makeElementGui")
        local title = cLogger:assertField(object, "Title")

        object.mainFlow = GuiMaker.run(object.parent, GuiConstructorArgs)
        object.mainFlow.title.caption = title

        object.titleLabel = SelectionCategoryLabel.new{
            gui = object,
            rawElement = object.mainFlow.title,
        }

        object:updateElements()
        object:updateExpanded()
        return object
    end,

    -- Restores the metatable of an AbstractGuiSelectionPanel, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object, metatable)
        AbstractGui.setmetatable(object, metatable)
        SelectionCategoryLabel.setmetatable(object.titleLabel)
    end,
}
MetaUtils.derive(AbstractGui.Metatable, AbstractGuiSelectionPanel.Metatable)

-- GuiMaker's arguments to build this GUI.
GuiConstructorArgs = {
    type = "flow",
    direction = "vertical",
    children = {
        {
            type = "label",
            caption = "?",
            name = "title",
        },{
            type = "scroll-pane",
            vertical_scroll_policy = "auto-and-reserve-space",
            name = "content",
        },
    },
}

-- Title label of a SelectionCategory.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * category: SelectionCategory object owning the label
-- * selectionWindow: selectionWindow object owning the category.
--
SelectionCategoryLabel = GuiElement.newSubclass{
    className = "graphApp/SelectionCategoryLabel",
    mandatoryFields = {"gui"},
    __index = {
        -- Implements GuiElement:onClick().
        onClick = function(self, event)
            self.gui.controller:select()
        end,
    }
}

return AbstractGuiSelectionPanel
