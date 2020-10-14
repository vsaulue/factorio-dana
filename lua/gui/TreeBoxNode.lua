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

local Array = require("lua/containers/Array")
local ClassLogger = require("lua/logger/ClassLogger")
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local TreeBoxNodeGui = require("lua/gui/TreeBoxNodeGui")

local cLogger = ClassLogger.new{className = "TreeBoxNode"}

local Metatable
local _new
local _setmetatable

-- Controller of a node in a TreeBox.
--
-- Implements Closeable.
--
-- RO Fields:
-- * caption: LocalisedString. Label of this node.
-- * chilren: Array<TreeBoxNode>. Children of this node.
-- * depth: int. Depth of this node in the tree (starts from 0).
-- * expanded: boolean. Flag set to show/collapse the list of chilren nodes.
-- * isLast: boolean. Flag set if this node is the last child of the parent node.
-- * selectable: boolan. Flag set if this node can be selected.
-- * selected: boolean. Flag set if this node is currently selected.
-- * treeBox: TreeBox. TreeBox object owning this node.
--
local TreeBoxNode = ErrorOnInvalidRead.new{
    -- Creates a new TreeBoxNode object.
    --
    -- Args:
    -- * object: Table to turn into a TreeBoxNode object (required fields: caption, depth, isLast).
    --
    -- Returns: The argument turned into a TreeBoxNode object.
    --
    new = function(object)
        local childDepth = 1 + cLogger:assertField(object, "depth")
        local treeBox = cLogger:assertField(object, "treeBox")
        cLogger:assertField(object, "caption")
        cLogger:assertField(object, "isLast")
        object.expanded = object.expanded or false
        object.selectable = object.selectable or false
        object.selected = false

        local children = Array.new(object.children)
        local count = children.count
        object.children = children
        for i=1,count do
            local child = children[i]
            child.depth = childDepth
            child.isLast = (i == count)
            child.treeBox = treeBox
            _new(child)
        end

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a TreeBoxNode object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        Array.setmetatable(object.children, _setmetatable)

        local gui = rawget(object, "gui")
        if gui then
            TreeBoxNodeGui.setmetatable(gui)
        end
    end,
}

-- Metatable of the TreeBoxNode class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        --
        -- Resets the gui field to nil.
        --
        close = function(self)
            Closeable.safeCloseField(self, "gui")
            self.children:close()
        end,

        -- Creates the GUI defined in this controller.
        --
        -- This TreeBoxNode must not have any GUI.
        --
        -- Args:
        -- * self: TreeBoxNode object.
        --
        makeGui = function(self, parent)
            local gui = rawget(self, "gui")
            cLogger:assert(not gui, "Attempt to make multiple GUIs.")

            self.gui = TreeBoxNodeGui.new{
                treeBoxNode = self,
                parent = parent,
            }
        end,

        -- Sets the "selected" value of this object.
        --
        -- Args:
        -- * self: TreeBoxNode.
        --
        setSelected = function(self, value)
            if self.selectable then
                local selected = not not value
                self.selected = selected

                local gui = rawget(self, "gui")
                if gui then
                    gui:updateSelected(selected)
                end
            end
        end,

        -- Changes the "expanded" value of this object.
        --
        -- Args:
        -- * self: TreeBoxNode object.
        --
        toggleExpanded = function(self)
            self.expanded = not self.expanded
            local gui = rawget(self, "gui")
            if gui then
                gui:updateExpanded()
            end
        end,
    }
}



_new = TreeBoxNode.new
_setmetatable = TreeBoxNode.setmetatable

return TreeBoxNode
