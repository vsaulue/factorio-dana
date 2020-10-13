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

local cLogger = ClassLogger.new{className = "TreeBoxNodeGui"}

local getExpandLabelCaption
local Metatable
local ExpandLabel

-- GUI elements of a TreeBoxNode object.
--
-- Implements Closeable.
--
-- RO Fields:
-- * childrenFlow: LuaGuiElement. GUI element containing the child nodes.
-- * expandLabel (optional): ExpandLabel. GUI wrapper for the clickable triangle.
-- * headerFlow: LuaGuiElement. GUI element containing the triangle & text.
-- * parent: LuaGuiElement. GUI element in which the TreeBoxNode is created.
-- * treeBoxNode: TreeBoxNode. Controller owning this GUI.
--
local TreeBoxNodeGui = ErrorOnInvalidRead.new{
    -- Creates a new TreeBoxNodeGui object.
    --
    -- Args:
    -- * object: Table to turn into a TreeBoxNodeGui object (required fields: treeBoxNode, parent).
    --
    -- Returns: The argument turned into a TreeBoxNodeGui object.
    --
    new = function(object)
        local treeBoxNode = cLogger:assertField(object, "treeBoxNode")
        local parent = cLogger:assertField(object, "parent")

        local children = treeBoxNode.children
        local depth = treeBoxNode.depth

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
            if treeBoxNode.isLast then
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
                treeBoxNode = treeBoxNode,
                rawElement = headerFlow.add{
                    type = "label",
                    caption = getExpandLabelCaption(treeBoxNode.expanded),
                    style = "clickable_label",
                },
            }
        else
            headerFlow.add{
                type = "label",
                caption = "─ ",
            }
        end
        headerFlow.add{
            type = "label",
            caption = treeBoxNode.caption,
        }

        local childrenFlow = parent.add{
            type = "flow",
            direction = "vertical",
            visible = treeBoxNode.expanded,
        }
        childrenFlow.style.vertical_spacing = 0
        object.childrenFlow = childrenFlow
        for i=1,children.count do
            children[i]:makeGui(childrenFlow)
        end

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of an TreeBoxNodeGui object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        ExpandLabel.safeSetmetatable(rawget(object, "expandLabel"))
    end,
}

-- Metatable of the TreeBoxNodeGui.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.headerFlow)
            GuiElement.safeDestroy(self.childrenFlow)
            Closeable.safeCloseField(self, "expandLabel")
        end,

        -- Updates the "expanded" state of this GUI.
        --
        -- Args:
        -- * self: TreeBoxNodeGui object.
        --
        updateExpanded = function(self)
            local expanded = self.treeBoxNode.expanded
            self.childrenFlow.visible = expanded
            self.expandLabel.rawElement.caption = getExpandLabelCaption(expanded)
        end,
    },
}

-- Callback of the triangle label used to expand/collapse the list of children.
ExpandLabel = GuiElement.newSubclass{
    className = "TreeBoxNodeGui/ExpandLabel",
    mandatoryFields = {"treeBoxNode"},
    __index = {
        onClick = function(self, event)
            self.treeBoxNode:toggleExpanded()
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

return TreeBoxNodeGui
