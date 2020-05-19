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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local SelectionCategoryLabel = require("lua/apps/graph/gui/SelectionCategoryLabel")

local CategoryInfos
local Metatable

-- Class holding the data of a category in a GUI selection window.
--
-- RO Fields:
-- * infoName: Name of the attached CategoryInfo object (see CategoryInfos).
-- * root: Main LuaGuiElement owned by this category.
--
local SelectionCategory = ErrorOnInvalidRead.new{
    -- Creates a new SelectionCategory.
    --
    -- Args:
    -- * selectionWindow: selectionWindow object that will own this category.
    -- * infoName: Name of the attached CategoryInfo object (see CategoryInfos).
    --
    -- Returns: the new SelectionCategory object.
    --
    make = function(selectionWindow, infoName)
        local categoryInfo = CategoryInfos[infoName]
        local result = {
            infoName = infoName,
            root = selectionWindow.frame.add{
                type = "flow",
                direction = "vertical",
                name = name,
                visible = false,
            },
        }
        result.root.add{
            type = "label",
            caption = {"", "▼ ", categoryInfo.title},
            name = "title",
        }
        result.root.add{
            type = "scroll-pane",
            vertical_scroll_policy = "auto-and-reserve-space",
            name = "content",
        }
        result.label = SelectionCategoryLabel.new{
            category = result,
            rawElement = result.root.title,
            selectionWindow = selectionWindow,
        }
        result.root.content.style.maximal_height = selectionWindow.maxCategoryHeight

        setmetatable(result, Metatable)
        return result
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        SelectionCategoryLabel.setmetatable(object.label)
    end,
}

-- Metatable of the SelectionCategory class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Replaces the currently displayed elements with a new set.
        --
        -- Args:
        -- * self: SelectionCategory object.
        -- * setOfElements: New elements to display.
        --
        setElements = function(self, setOfElements)
            local content = self.root.content
            local generateGuiElement = CategoryInfos[self.infoName].generateGuiElement
            local count = 0
            content.clear()
            for element in pairs(setOfElements) do
                generateGuiElement(content, element)
                count = count + 1
            end
            return count
        end,

        -- Expands (or collapses) the list of elements.
        --
        -- Args:
        -- * self: SelectionCategory object.
        -- * value: True to expand the list, false to hide it.
        --
        setExpanded = function(self, value)
            self.root.content.visible = value
            local titlePrefix
            if value then
                titlePrefix = "▼ "
            else
                titlePrefix = "▶ "
            end
            self.root.title.caption = {"", titlePrefix, CategoryInfos[self.infoName].title}
        end,

        -- Shows or hides this category.
        --
        -- Args:
        -- * self: SelectionCategory object.
        -- * value: True to show the category, false to hide it.
        --
        setVisible = function(self, value)
            self.root.visible = value
        end,
    }
}

-- Hardcoded map of "categories", indexed by their names.
--
-- Fields:
-- * title: Header line displayed in the GUI.
-- * generateGuiElement: function called to generate a LuaGuiElement from an item in a RendererSelection.
--
CategoryInfos = ErrorOnInvalidRead.new{
    vertices = ErrorOnInvalidRead.new{
        title = {"dana.apps.graph.selectionWindow.vertexCategory"},
        generateGuiElement = function(parent, vertexIndex)
            return parent.add{
                type = "label",
                caption = "- " .. vertexIndex.type .. "/" .. vertexIndex.rawPrototype.name,
            }
        end,
    },
    edges = ErrorOnInvalidRead.new{
        title = {"dana.apps.graph.selectionWindow.edgeCategory"},
        generateGuiElement = function(parent, edgeIndex)
            return parent.add{
                type = "label",
                caption = "- " .. edgeIndex.type .. "/" .. edgeIndex.rawPrototype.name,
            }
        end,
    },
    links = ErrorOnInvalidRead.new{
        title = {"dana.apps.graph.selectionWindow.linkCategory"},
        generateGuiElement = function(parent, treeLinkNode)
            return parent.add{
                type = "label",
                caption = "- { x= " .. treeLinkNode.x .. ", y= " ..treeLinkNode.y .. "}",
            }
        end,
    },
}

return SelectionCategory
