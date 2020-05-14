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

local cLogger = ClassLogger.new{className = "graphApp/SelectionWindow"}

local Categories
local CategoriesOrder
local Metatable

-- GUI to display selected parts of a graph.
--
-- RO fields:
-- * categories[name]: top-level LuaGuiElement of a given category, indexed by its name.
-- * frame: Gui frame containing all the LuaGuiElement of this class.
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
            caption = "Graph selection",
            direction = "vertical",
        }
        object.frame.location = {0,50}
        object.frame.style.maximal_height = rawPlayer.display_resolution.height - 50
        local scrollPane = object.frame.add{
            type = "scroll-pane",
            vertical_scroll_policy = "auto-and-reserve-space",
        }

        object.categories = ErrorOnInvalidRead.new()
        for _,name in ipairs(CategoriesOrder) do
            local category = Categories[name]
            local categoryFlow = scrollPane.add{
                type = "flow",
                direction = "vertical",
                name = name,
                visible = false,
            }
            local title = categoryFlow.add{
                type = "label",
                caption = category.title,
                name = "title",
            }
            categoryFlow.add{
                type = "flow",
                direction = "vertical",
                name = "content",
            }
            object.categories[name] = categoryFlow
        end

        object.noSelection = scrollPane.add{
            type = "label",
            caption = "Empty selection",
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
    end
}

-- Metatable of the SelectionWindow class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Sets the RendererSelection object to display in this GUI.
        --
        -- Args:
        -- * self: SelectionWindow object.
        -- * selection: RendererSelection object to display.
        --
        setSelection = function(self, selection)
            local total = 0
            for name,category in pairs(Categories) do
                    local content = self.categories[name].content
                    local generateGuiElement = category.generateGuiElement
                    local count = 0
                    content.clear()
                    for object in pairs(selection[name]) do
                        content.add(generateGuiElement(object))
                        count = count + 1
                    end
                    self.categories[name].visible = (count > 0)
                    total = total + count
            end
            self.noSelection.visible = (total == 0)
        end,
    },
}

-- Hardcoded map of "categories", indexed by their names.
--
-- Fields:
-- * title: Header line displayed in the GUI.
-- * generateGuiElement: function called to generate a LuaGuiElement from an item in a RendererSelection.
--
Categories = ErrorOnInvalidRead.new{
    vertices = ErrorOnInvalidRead.new{
        title = "Intermediates:",
        generateGuiElement = function(vertexIndex)
            return {
                type = "label",
                caption = "- " .. vertexIndex.type .. "/" .. vertexIndex.rawPrototype.name,
            }
        end,
    },
    edges = ErrorOnInvalidRead.new{
        title = "Transforms:",
        generateGuiElement = function(edgeIndex)
            return {
                type = "label",
                caption = "- " .. edgeIndex.type .. "/" .. edgeIndex.rawPrototype.name,
            }
        end,
    },
    links = ErrorOnInvalidRead.new{
        title = "Links:",
        generateGuiElement = function(treeLinkNode)
            return {
                type = "label",
                caption = "- { x= " .. treeLinkNode.x .. ", y= " ..treeLinkNode.y .. "}",
            }
        end,
    },
}

-- Array of category names, holding the order in which they are displayed.
CategoriesOrder = {"vertices", "edges", "links"}

return SelectionWindow
