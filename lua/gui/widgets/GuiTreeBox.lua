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

local cLogger = ClassLogger.new{className = "GuiTreeBox"}

local Metatable

-- GUI elements of a TreeBox object.
--
-- Implements Closeable.
--
-- RO Fields:
-- * flow: LuaGuiElement. Top-level GUI element containing all the nodes.
-- * parent: LuaGuiElement. GUI element in which the TreeBox is created.
-- * treeBox: TreeBox. Controller owning this GUI.
--
local GuiTreeBox = ErrorOnInvalidRead.new{
    -- Creates a new GuiTreeBox object.
    --
    -- Args:
    -- * object: Table to turn into a GuiTreeBox object (required fields: parent, treeBox).
    --
    -- Returns: The new GuiTreeBox object.
    --
    new = function(object)
        local treeBox = cLogger:assertField(object, "treeBox")
        local parent = cLogger:assertField(object, "parent")
        object.flow = parent.add{
            type = "flow",
            direction = "vertical",
        }
        object.flow.style.vertical_spacing = 0

        local roots = treeBox.roots
        for i=1,roots.count do
            roots[i]:open(object.flow)
        end

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of an GuiTreeBox object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the GuiTreeBox object.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.flow)
        end,
    },
}

return GuiTreeBox
