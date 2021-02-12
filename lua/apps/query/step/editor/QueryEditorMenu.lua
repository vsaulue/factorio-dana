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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MetaUtils = require("lua/class/MetaUtils")
local TreeBox = require("lua/gui/widgets/TreeBox")

local cLogger = ClassLogger.new{className = "QueryEditorMenu"}
local super = TreeBox.Metatable.__index

local Metatable
local parseNode

-- Controller of the menu of a query editor.
--
-- Inherits from TreeBox.
--
-- All selectable nodes in this tree have an additional field `editorName` (string).
-- It gives which params editor should be opened when this node is selected.
--
-- RO Fields:
-- * editorNameToNode[string]: TreeBoxNode. Map of nodes, indexed by their `editorName` field.
-- + TreeBox.
--
local QueryEditorMenu = ErrorOnInvalidRead.new{
    -- Creates a new QueryEditorMenu object.
    --
    -- Args:
    -- * object: table. Required fields: editorInterface.
    --
    -- Returns: QueryEditorMenu. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertField(object, "editorInterface")
        object.editorNameToNode = ErrorOnInvalidRead.new()
        TreeBox.new(object, Metatable)
        local roots = object.roots
        for i=1,roots.count do
            parseNode(object, roots[i])
        end
        return object
    end,

    -- Restores the metatable of an QueryEditorMenu object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        TreeBox.setmetatable(object, Metatable)
        ErrorOnInvalidRead.setmetatable(object.editorNameToNode)
    end,
}

-- Metatable of the QueryEditorMenu class.
Metatable = MetaUtils.derive(TreeBox.Metatable, {
    __index = {
        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.editorInterface:getGuiUpcalls()
        end,

        -- Overrides TreeBox:newRoot().
        newRoot = function(self, root)
            super.newRoot(self, root)
            parseNode(self, root)
        end,

        -- Implements TreeBox:onSelectionChanged().
        onSelectionChanged = function(self)
            self.editorInterface:setParamsEditor(self.selection.editorName)
        end,

        -- Selects a node having the specified editorName field.
        --
        -- Args:
        -- * self: QueryEditorMenu.
        -- * name: string. Value of `editorName` to look for.
        --
        selectByName = function(self, name)
            local node = nil
            if name then
                node = self.editorNameToNode[name]
            end
            super.setSelection(self, node)
        end,
    },
})

-- Parses a node to fill the `editorNameToNode` map.
--
-- Args:
-- * self: QueryEditorMenu.
-- * node: TreeBoxNode. Any node in `self`.
--
parseNode = function(self, node)
    if node.selectable then
        self.editorNameToNode[node.editorName] = node
    end
    local children = node.children
    for i=1,children.count do
        parseNode(self, children[i])
    end
end

return QueryEditorMenu
