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

local AbstractSelectionPanel = require("lua/apps/graph/gui/AbstractSelectionPanel")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiEdgeSelectionPanel = require("lua/apps/graph/gui/GuiEdgeSelectionPanel")
local MetaUtils = require("lua/class/MetaUtils")

local Metatable

-- AbstractSelectionPanel displaying `RendererSelection.nodes.hyperEdge` elements.
--
-- RO Fields:
-- * elements (override): Set<PrepNodeIndex>.
--
local EdgeSelectionPanel = ErrorOnInvalidRead.new{
    -- Creates a new EdgeSelectionPanel object.
    --
    -- RO Fields:
    -- * object: table. Required fields: see AbstractSelectionPanel.new().
    --
    -- Returns: EdgeSelectionPanel. The `object` argument turned into the desired type.
    --
    new = function(object)
        return AbstractSelectionPanel.new(object, Metatable)
    end,

    -- Restores the metatable of an EdgeSelectionPanel, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        AbstractSelectionPanel.setmetatable(object, Metatable, GuiEdgeSelectionPanel.setmetatable)
    end,
}

-- Metatable of the EdgeSelectionPanel class.
Metatable = {
    __index = {
        -- Implements AbstractSelectionPanel.extractElements().
        extractElements = function(rendererSelection)
            return rendererSelection.nodes.hyperEdge
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiEdgeSelectionPanel.new{
                controller = self,
                parent = parent,
            }
        end,
    },
}
MetaUtils.derive(AbstractSelectionPanel.Metatable, Metatable)

return EdgeSelectionPanel
