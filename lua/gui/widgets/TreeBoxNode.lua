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

local AbstractGuiController = require("lua/gui/AbstractGuiController")
local Array = require("lua/containers/Array")
local ClassLogger = require("lua/logger/ClassLogger")
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MetaUtils = require("lua/class/MetaUtils")
local GuiTreeBoxNode = require("lua/gui/widgets/GuiTreeBoxNode")

local cLogger = ClassLogger.new{className = "TreeBoxNode"}

local computePrefixes
local Metatable
local _new
local _setmetatable

-- Controller of a node in a TreeBox.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * caption: LocalisedString. Label of this node.
-- * chilren: Array<TreeBoxNode>. Children of this node.
-- * childrenPrefix: string. Prefix for the children's lines.
-- * expanded: boolean. Flag set to show/collapse the list of chilren nodes.
-- * gui (override): GuiTreeBoxNode or nil.
-- * parent (optional): TreeBoxNode. Parent node (or nil if this is a root).
-- * selectable: boolan. Flag set if this node can be selected.
-- * selected: boolean. Flag set if this node is currently selected.
-- * titlePrefix: string. Prefix of the header line of this node.
-- * treeBox: TreeBox. TreeBox object owning this node.
--
local TreeBoxNode = ErrorOnInvalidRead.new{
    -- Creates a new TreeBoxNode object.
    --
    -- Args:
    -- * object: Table to turn into a TreeBoxNode object (required fields: caption, treeBox).
    --
    -- Returns: The argument turned into a TreeBoxNode object.
    --
    new = function(object)
        local treeBox = cLogger:assertField(object, "treeBox")
        cLogger:assertField(object, "caption")
        object.children = Array.new(object.children)
        object.expanded = object.expanded or false
        object.selectable = object.selectable or false
        object.selected = false

        AbstractGuiController.new(object, Metatable)
        computePrefixes(object)

        local children = object.children
        for i=1,children.count do
            local child = children[i]
            child.parent = object
            child.treeBox = treeBox
            _new(child)
        end

        return object
    end,

    -- Restores the metatable of a TreeBoxNode object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiTreeBoxNode.setmetatable)
        Array.setmetatable(object.children, _setmetatable)
    end,
}

-- Metatable of the TreeBoxNode class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractGuiController:close().
        close = function(self)
            Closeable.safeCloseField(self, "gui")
            self.children:close()
        end,

        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.treeBox:getGuiUpcalls()
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiTreeBoxNode.new{
                controller = self,
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
    },
}
MetaUtils.derive(AbstractGuiController.Metatable, Metatable)

-- Refreshes the values of the `titlePrefix` and `childrenPrefix` fields.
--
-- Args:
-- * self: TreeBoxNode.
--
computePrefixes = function(self)
    local titlePrefix = ""
    local childrenPrefix = ""
    local parent = rawget(self, "parent")
    if parent then
        local prefix = parent.childrenPrefix
        if parent.children[parent.children.count] ~= self then
            titlePrefix = prefix .. "├"
            childrenPrefix = prefix .. "│"
        else
            titlePrefix = prefix .. "└"
            childrenPrefix = prefix .. " "
        end
    end
    self.titlePrefix = titlePrefix
    self.childrenPrefix = childrenPrefix
end

_new = TreeBoxNode.new
_setmetatable = TreeBoxNode.setmetatable

return TreeBoxNode
