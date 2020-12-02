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
local EdgeSelectionPanel = require("lua/apps/graph/gui/EdgeSelectionPanel")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiSelectionWindow = require("lua/apps/graph/gui/GuiSelectionWindow")
local LinkSelectionPanel = require("lua/apps/graph/gui/LinkSelectionPanel")
local MetaUtils = require("lua/class/MetaUtils")
local RendererSelection = require("lua/renderers/RendererSelection")
local OneToOneSelectionPanel = require("lua/apps/graph/gui/OneToOneSelectionPanel")
local VertexSelectionPanel = require("lua/apps/graph/gui/VertexSelectionPanel")

local cLogger = ClassLogger.new{className = "graphApp/SelectionWindow"}
local super = AbstractGuiController.Metatable.__index

local Panels
local Metatable

-- GUI to display selected parts of a graph.
--
-- RO fields:
-- * appResources: AppResources. Resources of the owning application.
-- * location: GuiLocation. Initial location of this frame.
-- * maxHeight: int. Maximum height of this frame
-- * panels[int]: AbstractSelectionPanel. Panels owned by this controller (same indices as `Panels`).
-- * selection: RendererSelection. Elements being displayed.
--
local SelectionWindow = ErrorOnInvalidRead.new{
    -- Creates a new SelectionWindow object.
    --
    -- Args:
    -- * object: table. Required field: appResources, location, maxHeight.
    --
    -- Returns: The argument turned into a SelectionWindow object.
    --
    new = function(object)
        cLogger:assertField(object, "appResources")
        cLogger:assertField(object, "location")
        cLogger:assertField(object, "maxHeight")

        object.panels = ErrorOnInvalidRead.new()
        for index,categoryClass in ipairs(Panels) do
            local category = categoryClass.new{
                selectionWindow = object,
            }
            object.panels[index] = category
        end

        AbstractGuiController.new(object, Metatable)
        return object
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiSelectionWindow.setmetatable)
        MetaUtils.safeSetField(object, "selection", RendererSelection.setmetatable)
        ErrorOnInvalidRead.setmetatable(object.panels)
        for index,classTable in ipairs(Panels) do
            classTable.setmetatable(object.panels[index])
        end
    end,
}

-- Metatable of the SelectionWindow class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Overrides AbstractGuiController:close().
        close = function(self)
            super.close(self)
            Closeable.closeMapValues(self.panels)
        end,

        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.appResources
        end,

        -- Gives Dana's selection tool to the player.
        --
        -- Args:
        -- * self: SelectionWindow.
        --
        giveSelectionTool = function(self)
            local rawPlayer = self.appResources.rawPlayer
            rawPlayer.clear_cursor()
            rawPlayer.cursor_stack.set_stack{
                name = "dana-select",
            }
        end,

        -- Expands the element list of a given category, and collapses the others.
        --
        -- Args:
        -- * self: SelectionWindow.
        -- * selectedPanel: AbstractSelectionPanel. Panel to expand.
        --
        selectPanel = function(self, selectedPanel)
            for _,panel in pairs(self.panels) do
                panel:setExpanded(panel == selectedPanel)
            end
        end,

        -- Tests if this SelectionWindow currently displays any element.
        --
        -- Args:
        -- * self: SelectionWindow.
        --
        -- Returns: boolean. False if it has 0 element, true otherwise.
        --
        hasElements = function(self)
            local result = true
            for _,panel in ipairs(self.panels) do
                result = result and panel:hasElements()
            end
            return result
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiSelectionWindow.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Sets the RendererSelection object to display in this GUI.
        --
        -- Args:
        -- * self: SelectionWindow object.
        -- * selection: RendererSelection object to display.
        --
        setSelection = function(self, selection)
            self.selection = selection
            local noExpanded = true
            for _,panel in ipairs(self.panels) do
                panel:updateElements(selection)
                if noExpanded and panel:hasElements() then
                    panel:setExpanded(true)
                    noExpanded = false
                else
                    panel:setExpanded(false)
                end
            end

            local gui = rawget(self, "gui")
            if gui then
                gui:setHasElements(not noExpanded)
            end
        end,
    },
}
MetaUtils.derive(AbstractGuiController.Metatable, Metatable)

-- Array<table>. Classes of AbstractSelectionPanel to instanciate.
Panels = Array.new{
    VertexSelectionPanel,
    OneToOneSelectionPanel,
    EdgeSelectionPanel,
    LinkSelectionPanel,
}

return SelectionWindow
