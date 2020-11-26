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
local GuiElement = require("lua/gui/GuiElement")
local GuiTreeBox = require("lua/gui/GuiTreeBox")
local TreeBoxNode = require("lua/gui/TreeBoxNode")

local cLogger = ClassLogger.new{className = "TreeBox"}

local Metatable

-- GUI controller for a listbox with a tree-like structure.
--
-- Implements Closeable.
--
-- RO Fields:
-- * roots: Array<TreeBoxNode>. Set of top-level nodes of the box.
-- * gui (optional): GuiTreeBox. GUI owned by this controller (nil if no GUI is instanciated).
-- * selection (optional): TreeBoxNode. Currently selected node (nil if no node is selected).
--
local TreeBox = ErrorOnInvalidRead.new{
    -- Creates a new TreeBox object.
    --
    -- Args:
    -- * object: Table to turn into a TreeBox object.
    --
    -- Returns: The argument turned into a TreeBox object.
    --
    new = function(object)
        local roots = Array.new(object.roots)
        local count = roots.count
        for i=1,count do
            local node = roots[i]
            node.depth = 0
            node.treeBox = object
            node.isLast = (i == count)
            TreeBoxNode.new(node)
        end
        object.roots = roots

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of an TreeBox object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        Array.setmetatable(object.roots, TreeBoxNode.setmetatable)

        local gui = rawget(object, "gui")
        if gui then
            GuiTreeBox.setmetatable(gui)
        end
    end,
}

-- Metatable of the TreeBox class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        --
        -- Resets the gui field to nil.
        --
        close = function(self)
            Closeable.safeCloseField(self, "gui")
            self.roots:close()
        end,

        -- Creates the GUI defined in this controller.
        --
        -- This TreeBox must not have any GUI.
        --
        -- Args:
        -- * self: TreeBox object.
        --
        makeGui = function(self, parent)
            local gui = rawget(self, "gui")
            cLogger:assert(not gui, "Attempt to make multiple GUIs.")

            self.gui = GuiTreeBox.new{
                treeBox = self,
                parent = parent,
            }
        end,

        -- Sets which node is currently selected in this TreeBox.
        --
        -- Args:
        -- * self: TreeBox.
        -- * node: TreeBoxNode. New node being selected (nil to select none).
        --
        setSelection = function(self, node)
            local oldSelection = rawget(self, "selection")
            if oldSelection ~= node then
                if oldSelection then
                    oldSelection:setSelected(false)
                end
                cLogger:assert(node.treeBox == self, "Attempt to select a node from another tree.")
                if node and node.selectable then
                    self.selection = node
                    node:setSelected(true)
                else
                    self.selection = nil
                end
            end
        end,
    }
}

return TreeBox
