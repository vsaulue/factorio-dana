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
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "AbstractSelectionPanel"}

-- Class displaying a specific category of a RendererSelection in a SelectionWindow.
--
-- RO Fields:
-- * elements[any]: any. Map containing the displayed elements (types depends on the category).
-- * expanded: boolean. True if elements are shown, false if they are hidden.
-- * gui (override): AbstractGuiSelectionPanel.
-- * selectionWindow: SelectionWindow. Parent controller.
--
local AbstractSelectionPanel = ErrorOnInvalidRead.new{
    -- Metatable of the AbstractSelectionPanel class.
    Metatable = {
        __index = {
            -- Extracts the elements to display in this panel from a RendererSelection.
            --
            -- NOT a method.
            --
            -- Args:
            -- * rendererSelection: RendererSelection. Object to parse for elements.
            --
            -- Returns: Map<any,any>. The map of elements to display in this panel.
            --[[
            extractElements = function(rendererSelection) end,
            --]]

            -- Implements AbstractGuiController:getGuiUpcalls().
            getGuiUpcalls = function(self)
                return self.selectionWindow.appResources
            end,

            -- Checks if this panel displays any element.
            --
            -- Args:
            -- * self: AbstractSelectionPanel.
            --
            -- Returns: boolean. True if this panel contains an element.
            --
            hasElements = function(self)
                local elements = rawget(self, "elements")
                return elements and next(elements)
            end,

            -- Selects this category in the window.
            --
            -- Args:
            -- * self: AbstractSelectionPanel.
            --
            select = function(self)
                self.selectionWindow:selectPanel(self)
            end,

            -- Sets the `expanded` field of this object.
            --
            -- Args:
            -- * self: AbstractSelectionPanel.
            -- * value: boolean.
            --
            setExpanded = function(self, value)
                self.expanded = value

                local gui = rawget(self, "gui")
                if gui then
                    gui:updateExpanded()
                end
            end,

            -- Changes the elements displayed by this object.
            --
            -- Args:
            -- * self: AbstractSelectionPanel.
            -- * rendererSelection: RendererSelection. Object containing the new elements to display.
            --
            updateElements = function(self, rendererSelection)
                local elements = self.extractElements(rendererSelection)
                self.elements = elements

                local gui = rawget(self, "gui")
                if gui then
                    gui:updateElements()
                end
            end,
        },
    },

    -- Creates a new AbstractSelectionPanel object.
    --
    -- Args:
    -- * object: table. Required fields: selectionWindow.
    --
    -- Returns: AbstractSelectionPanel. The `object` argument turned into the desired type.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "selectionWindow")
        object.expanded = not not object.expanded
        AbstractGuiController.new(object, metatable)
        cLogger:assertField(object, "extractElements")
        return object
    end,

    -- Restores the metatable of an AbstractSelectionPanel, and all its owned objects.
    setmetatable = AbstractGuiController.setmetatable,
}
MetaUtils.derive(AbstractGuiController.Metatable, AbstractSelectionPanel.Metatable)

return AbstractSelectionPanel
