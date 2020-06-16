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
local SelectionCategory = require("lua/apps/graph/gui/SelectionCategory")

local cLogger = ClassLogger.new{className = "graphApp/SelectionWindow"}

local Categories
local CategoriesOrder
local Metatable

-- GUI to display selected parts of a graph.
--
-- RO fields:
-- * categories[name]: top-level LuaGuiElement of a given category, indexed by its name.
-- * frame: Gui frame containing all the LuaGuiElement of this class.
-- * maxCategoryHeight: Maximum height of a category.
-- * noSelection: Gui flow displaying the "Empty selection" message.
-- * rawPlayer: LuaPlayer object.
--
local SelectionWindow = ErrorOnInvalidRead.new{
    -- Creates a new SelectionWindow object.
    --
    -- Args:
    -- * object: Table to turn into a SelectionWindow object (required field: rawPlayer).
    --
    -- Returns: The argument turned into a SelectionWindow object.
    --
    new = function(object)
        local rawPlayer = cLogger:assertField(object, "rawPlayer")
        object.frame = rawPlayer.gui.screen.add{
            type = "frame",
            caption = {"dana.apps.graph.selectionWindow.title"},
            direction = "vertical",
        }
        object.frame.location = {0,50}
        object.frame.style.maximal_height = rawPlayer.display_resolution.height - 50
        object.maxCategoryHeight = object.frame.style.maximal_height - (1+#CategoriesOrder)*32

        local categoryHeight = object.frame.style.maximal_height - (1+#CategoriesOrder)*20

        object.categories = ErrorOnInvalidRead.new()
        for _,name in ipairs(CategoriesOrder) do
            object.categories[name] = SelectionCategory.make(object, name)
        end

        object.noSelection = object.frame.add{
            type = "label",
            caption = {"dana.apps.graph.selectionWindow.emptyCategory"},
        }

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        ErrorOnInvalidRead.setmetatable(object.categories)
        for _,category in pairs(object.categories) do
            SelectionCategory.setmetatable(category)
        end
    end
}

-- Metatable of the SelectionWindow class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Releases all API resources of this object.
        --
        -- Args:
        -- * self: SelectionWindow object.
        --
        close = function(self)
            GuiElement.destroy(self.frame)
            self.frame = nil
        end,

        -- Expands the element list of a given category, and collapses the others.
        --
        -- Args:
        -- * self: SelectionWindow object.
        -- * categoryToExpand: SelectionCategory to expand.
        --
        expandCategory = function(self, categoryToExpand)
            for _,category in pairs(self.categories) do
                category:setExpanded(category == categoryToExpand)
            end
        end,

        -- Sets the RendererSelection object to display in this GUI.
        --
        -- Args:
        -- * self: SelectionWindow object.
        -- * selection: RendererSelection object to display.
        --
        setSelection = function(self, selection)
            local total = 0
            for name,category in pairs(self.categories) do
                    local count = category:setElements(selection)
                    self.categories[name]:setVisible(count > 0)
                    self.categories[name]:setExpanded(count > 0 and total == 0)
                    total = total + count
            end
            self.noSelection.visible = (total == 0)
        end,
    },
}

-- Array of category names, holding the order in which they are displayed.
CategoriesOrder = {"vertices", "edges", "links"}

return SelectionWindow
