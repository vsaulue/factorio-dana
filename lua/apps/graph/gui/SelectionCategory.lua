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
local GuiElement = require("lua/gui/GuiElement")

local CategoryInfos
local EdgeTypeIcon
local LinkArrowColor
local LinkArrowLabel
local Metatable
local SelectionCategoryLabel
local VertexTypeIcon

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
        -- * rendererSelection: RendererSelection containing the new items to display.
        --
        setElements = function(self, rendererSelection)
            self.root.content.clear()
            return CategoryInfos[self.infoName].generateGuiElements(self, rendererSelection)
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
-- * generateGuiElement: function called to generate LuaGuiElement objects for a new selection.
--
CategoryInfos = ErrorOnInvalidRead.new{
    vertices = ErrorOnInvalidRead.new{
        title = {"dana.apps.graph.selectionWindow.vertexCategory"},
        generateGuiElements = function(self, rendererSelection)
            local parent = self.root.content
            local count = 0
            for vertexIndex in pairs(rendererSelection.vertices) do
                local flow = parent.add{
                    type = "flow",
                    direction = "horizontal",
                }

                flow.add(VertexTypeIcon[vertexIndex.type])
                flow.typeIcon.style.minimal_width = 32

                flow.add{
                    type = "sprite",
                    name = "vertexIcon",
                    sprite = vertexIndex.type .. "/" .. vertexIndex.rawPrototype.name,
                }
                flow.vertexIcon.style.minimal_width = 32

                flow.add{
                    type = "label",
                    caption = vertexIndex.rawPrototype.localised_name,
                }
                count = count + 1
            end
            return count
        end,
    },

    edges = ErrorOnInvalidRead.new{
        title = {"dana.apps.graph.selectionWindow.edgeCategory"},
        generateGuiElements = function(self, rendererSelection)
            local parent = self.root.content
            local count = 0
            for edgeIndex in pairs(rendererSelection.edges) do
                local flow = parent.add{
                    type = "flow",
                    direction = "horizontal",
                }

                flow.add(EdgeTypeIcon[edgeIndex.type])
                flow.typeIcon.style.minimal_width = 32

                flow.add{
                    type = "sprite",
                    name = "edgeIcon",
                    sprite = edgeIndex.type .. "/" .. edgeIndex.rawPrototype.name,
                }
                flow.edgeIcon.style.minimal_width = 32

                flow.add{
                    type = "label",
                    caption = edgeIndex.rawPrototype.localised_name,
                }
                count = count + 1
            end
            return count
        end,
    },

    links = ErrorOnInvalidRead.new{
        title = {"dana.apps.graph.selectionWindow.linkCategory"},
        generateGuiElements = function(self, rendererSelection)
            local parent = self.root.content
            local result = 0
            for channelIndex,edgeIndices in pairs(rendererSelection:makeAggregatedLinkSelection()) do
                local flow = parent.add{
                    type = "flow",
                    direction = "horizontal",
                }

                flow.add{
                    type = "sprite",
                    sprite = channelIndex.vertexIndex.type .. "/" .. channelIndex.vertexIndex.rawPrototype.name,
                    tooltip = channelIndex.vertexIndex.rawPrototype.localised_name,
                }

                local arrowLabel = flow.add(LinkArrowLabel[channelIndex.isFromVertexToEdge])
                arrowLabel.style.font_color = LinkArrowColor[channelIndex.isFromVertexToEdge]

                local count = 0
                for leaf in pairs(edgeIndices) do
                    count = count + 1
                end
                if count <= 5 then
                    for edgeIndex in pairs(edgeIndices) do
                        flow.add{
                            type = "sprite",
                            sprite = edgeIndex.type .. "/" .. edgeIndex.rawPrototype.name,
                            tooltip = edgeIndex.rawPrototype.localised_name,
                        }
                    end
                else
                    flow.add{
                        type = "label",
                        caption = {"dana.apps.graph.selectionWindow.n-transforms", count},
                    }
                end
                result = result + 1
            end
            return result
        end,
    },
}

-- Map[edgeIndex.type]: LuaGuiElement construction info for a sprite representing the type of a edge.
--
EdgeTypeIcon = ErrorOnInvalidRead.new{
    entity = {
        type = "sprite",
        name = "typeIcon",
        sprite = "dana-boiler-icon",
        tooltip = {"dana.apps.graph.selectionWindow.boilerType"},
    },
    recipe = {
        type = "sprite",
        name = "typeIcon",
        sprite = "dana-recipe-icon",
        tooltip = {"dana.apps.graph.selectionWindow.recipeType"},
    },
}

-- Map[isFromVertexToEdge]: Map giving the color of the arrow for link selection.
LinkArrowColor = ErrorOnInvalidRead.new{
    [true] = {r = 1, g = 0.6, b = 0.6, a = 1},
    [false] = {r = 0.6, g = 1, b = 0.6, a = 1},
}

-- Map[isFromVertexToEdge]: LuaGuiElement construction info of the arrow for link selection.
LinkArrowLabel = ErrorOnInvalidRead.new{
    [true] = {
        type = "label",
        caption = "⟶",
        tooltip = {"dana.apps.graph.selectionWindow.ingredientLink"},
    },
    [false] = {
        type = "label",
        caption = "⟵",
        tooltip = {"dana.apps.graph.selectionWindow.productLink"},
    },
}

-- Title label of a SelectionCategory.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * category: SelectionCategory object owning the label
-- * selectionWindow: selectionWindow object owning the category.
--
SelectionCategoryLabel = GuiElement.newSubclass{
    className = "graphApp/SelectionCategoryLabel",
    mandatoryFields = {"category", "selectionWindow"},
    __index = {
        -- Implements GuiElement.onClick().
        --
        onClick = function(self, event)
            self.selectionWindow:expandCategory(self.category)
        end,
    }
}

-- Map[vertexIndex.type]: LuaGuiElement construction info for a sprite representing the type of a vertex.
--
VertexTypeIcon = ErrorOnInvalidRead.new{
    fluid = {
        type = "sprite",
        name = "typeIcon",
        sprite = "dana-fluid-icon",
        tooltip = {"dana.apps.graph.selectionWindow.fluidType"},
    },
    item = {
        type = "sprite",
        name = "typeIcon",
        sprite = "dana-item-icon",
        tooltip = {"dana.apps.graph.selectionWindow.itemType"},
    },
}

return SelectionCategory
