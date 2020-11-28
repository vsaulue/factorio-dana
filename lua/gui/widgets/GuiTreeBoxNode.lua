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
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local MetaUtils = require("lua/class/MetaUtils")

local getExpandLabelCaption
local Metatable
local ExpandLabel
local SelectedColor
local SelectLabel
local SelectableColor
local UnselectableColor

-- GUI elements of a TreeBoxNode object.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * childrenFlow: LuaGuiElement. GUI element containing the child nodes.
-- * controller (override): TreeBoxNode.
-- * expandLabel (optional): ExpandLabel. GUI wrapper for the clickable triangle.
-- * headerFlow: LuaGuiElement. GUI element containing the triangle & text.
-- + AbstractGui.
--
local GuiTreeBoxNode = ErrorOnInvalidRead.new{
    -- Creates a new GuiTreeBoxNode object.
    --
    -- Args:
    -- * object: Table to turn into a GuiTreeBoxNode object (required fields: controller, parent).
    --
    -- Returns: The argument turned into a GuiTreeBoxNode object.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)
        local controller = object.controller
        local parent = object.parent

        local children = controller.children
        local depth = controller.depth

        local headerFlow = parent.add{
            type = "flow",
            direction = "horizontal",
        }
        headerFlow.style.horizontal_spacing = 0
        object.headerFlow = headerFlow
        if depth > 0 then
            local prefix = ""
            for i=1,depth-1 do
                prefix = prefix .. "│"
            end
            if controller.isLast then
                prefix = prefix .. "└"
            else
                prefix = prefix .. "├"
            end
            headerFlow.add{
                type = "label",
                caption = prefix,
            }
        end
        if children.count > 0 then
            object.expandLabel = ExpandLabel.new{
                controller = controller,
                rawElement = headerFlow.add{
                    type = "label",
                    caption = getExpandLabelCaption(controller.expanded),
                    style = "clickable_label",
                },
            }
        else
            headerFlow.add{
                type = "label",
                caption = "─ ",
            }
        end
        local captionLabel = headerFlow.add{
            type = "label",
            caption = controller.caption,
        }
        if controller.selectable then
            object.selectLabel = SelectLabel.new{
                controller = controller,
                rawElement = captionLabel,
            }
            captionLabel.style = "clickable_label"
        else
            captionLabel.style.font_color = UnselectableColor
        end

        local childrenFlow = parent.add{
            type = "flow",
            direction = "vertical",
            visible = controller.expanded,
        }
        childrenFlow.style.vertical_spacing = 0
        object.childrenFlow = childrenFlow
        for i=1,children.count do
            children[i]:open(childrenFlow)
        end

        return object
    end,

    -- Restores the metatable of an GuiTreeBoxNode object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        ExpandLabel.safeSetmetatable(rawget(object, "expandLabel"))
        SelectLabel.safeSetmetatable(rawget(object, "selectLabel"))
    end,
}

-- Metatable of the GuiTreeBoxNode.
Metatable = {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.headerFlow)
            GuiElement.safeDestroy(self.childrenFlow)
            Closeable.safeCloseField(self, "expandLabel")
            Closeable.safeCloseField(self, "selectLabel")
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.headerFlow.valid and self.childrenFlow.valid
        end,

        -- Updates the "expanded" state of this GUI.
        --
        -- Args:
        -- * self: GuiTreeBoxNode object.
        --
        updateExpanded = function(self)
            if self:sanityCheck() then
                local expanded = self.controller.expanded
                self.childrenFlow.visible = expanded
                self.expandLabel.rawElement.caption = getExpandLabelCaption(expanded)
            end
        end,

        -- Updates the "selected" state of this GUI.
        --
        -- Args:
        -- * self: GuiTreeBoxNode.
        --
        updateSelected = function(self)
            if self:sanityCheck() then
                local selected = self.controller.selected
                local labelStyle = self.selectLabel.rawElement.style
                if selected then
                    labelStyle.font = "default-bold"
                    labelStyle.font_color = SelectedColor
                else
                    labelStyle.font = "default"
                    labelStyle.font_color = SelectableColor
                end
            end
        end,
    },
}
MetaUtils.derive(AbstractGui.Metatable, Metatable)

-- Callback of the triangle label used to expand/collapse the list of children.
ExpandLabel = GuiElement.newSubclass{
    className = "GuiTreeBoxNode/ExpandLabel",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller:toggleExpanded()
        end,
    },
}

-- Generates the caption of the ExpandLabel.
--
-- Args:
-- * expanded: Boolean. Current "expand" value of the TreeBoxNode.
--
getExpandLabelCaption = function(expanded)
    local result = "▶ "
    if expanded then
        result = "▼ "
    end
    return result
end

-- Color of the text label when the node is selectable.
SelectableColor = {1, 1, 1}

-- Color of the text label when the node is selected.
SelectedColor = {0.98, 0.66, 0.22}

-- Callback for the clickable label used to select a node.
SelectLabel = GuiElement.newSubclass{
    className = "GuiTreeBoxNode/SelectLabel",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            local controller = self.controller
            controller.treeBox:setSelection(controller)
        end,
    }
}

-- Color of the text label when the node is not selectable.
UnselectableColor = {0.7, 0.7, 0.7}

return GuiTreeBoxNode
