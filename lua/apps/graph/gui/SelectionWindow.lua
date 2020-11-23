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
local EdgeSelectionPanel = require("lua/apps/graph/gui/EdgeSelectionPanel")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local LinkSelectionPanel = require("lua/apps/graph/gui/LinkSelectionPanel")
local OneToOneSelectionPanel = require("lua/apps/graph/gui/OneToOneSelectionPanel")
local VertexSelectionPanel = require("lua/apps/graph/gui/VertexSelectionPanel")

local cLogger = ClassLogger.new{className = "graphApp/SelectionWindow"}

local Categories
local Metatable
local SelectToolButton

-- GUI to display selected parts of a graph.
--
-- RO fields:
-- * categories[name]: top-level LuaGuiElement of a given category, indexed by its name.
-- * frame: Gui frame containing all the LuaGuiElement of this class.
-- * maxCategoryHeight: Maximum height of a category.
-- * noSelection: Gui flow displaying the "Empty selection" message.
-- * rawPlayer: LuaPlayer object.
-- * selectToolButton: SelectToolButton of this window.
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

        object.selectToolButton = SelectToolButton.new{
            rawElement = object.frame.add{
                type = "button",
                caption = {"dana.apps.graph.selectionWindow.selectButton"},
            },
            rawPlayer = rawPlayer,
        }
        object.selectToolButton.rawElement.style.horizontally_stretchable = true

        local categoryHeight = object.frame.style.maximal_height - (1+Categories.count)*20
        object.categories = ErrorOnInvalidRead.new()
        for index,categoryClass in ipairs(Categories) do
            local category = categoryClass.new{
                maxHeight = categoryHeight,
                selectionWindow = object,
            }
            object.categories[index] = category
            category:open(object.frame)
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
        SelectToolButton.setmetatable(object.selectToolButton)
        ErrorOnInvalidRead.setmetatable(object.categories)
        for index,classTable in ipairs(Categories) do
            classTable.setmetatable(object.categories[index])
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
            GuiElement.safeDestroy(self.frame)
            Closeable.closeMapValues(self.categories)
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
            local noExpanded = true
            for _,category in ipairs(self.categories) do
                category:updateElements(selection)
                if noExpanded and category:hasElements() then
                    category:setExpanded(true)
                    noExpanded = false
                end
            end
            self.noSelection.visible = noExpanded
        end,
    },
}

-- Array<table>. Classes of AbstractSelectionPanel to instanciate.
Categories = Array.new{
    VertexSelectionPanel,
    OneToOneSelectionPanel,
    EdgeSelectionPanel,
    LinkSelectionPanel,
}

-- Button to give the dana-select item to the player.
--
-- RO Fields:
-- * rawPlayer: Player to give the item to.
--
SelectToolButton = GuiElement.newSubclass{
    className = "GraphApp/SelectToolButton",
    mandatoryFields = {"rawPlayer"},
    __index = {
        onClick = function(self, event)
            self.rawPlayer.clean_cursor()
            self.rawPlayer.cursor_stack.set_stack{
                name = "dana-select",
            }
        end,
    },
}

return SelectionWindow
