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

local AbstractGuiSelectionPanel = require("lua/apps/graph/gui/AbstractGuiSelectionPanel")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")
local Set = require("lua/containers/Set")

local LinkArrowLabel
local LinkArrowColor
local Metatable

-- Instanciated GUI of an LinkSelectionPanel.
--
-- Inherits from AbstractGuiSelectionPanel.
--
-- RO Fields:
-- * controller (override): LinkSelectionPanel.
--
local GuiLinkSelectionPanel = ErrorOnInvalidRead.new{
    -- Creates a new GuiLinkSelectionPanel object.
    --
    -- RO Fields:
    -- * object: table. Required fields: see AbstractGuiSelectionPanel.new().
    --
    -- Returns: GuiLinkSelectionPanel. The `object` argument turned into the desired type.
    --
    new = function(object)
        return AbstractGuiSelectionPanel.new(object, Metatable)
    end,

    -- Restores the metatable of an GuiLinkSelectionPanel, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        AbstractGuiSelectionPanel.setmetatable(object, Metatable)
    end,
}

-- Metatable of the GuiLinkSelectionPanel class.
Metatable = {
    __index = {
        -- Implements AbstractGuiSelectionPanel.makeElementGui().
        --
        -- Args:
        -- * parent: LuaGuiElement.
        -- * linkIndex: LinkIndex.
        -- * nodeIndices: Set<PrepNodeIndex>.
        --
        makeElementGui = function(parent, linkIndex, nodeIndices)
            local elemFlow = GuiMaker.run(parent, {
                type = "flow",
                direction = "horizontal",
                children = {
                    {
                        type = "sprite",
                        sprite = linkIndex.symbol.spritePath,
                        tooltip = linkIndex.symbol.localisedName,
                    },
                    LinkArrowLabel[linkIndex.isFromRoot],
                },
            })
            elemFlow.arrowLabel.style.font_color = LinkArrowColor[linkIndex.isFromRoot]

            local count = Set.count(nodeIndices)
            if count <= 5 then
                for nodeIndex in pairs(nodeIndices) do
                    elemFlow.add{
                        type = "sprite",
                        sprite = nodeIndex.index.spritePath,
                        tooltip = nodeIndex.index.localisedName,
                    }
                end
            else
                elemFlow.add{
                    type = "label",
                    caption = {"dana.apps.graph.selectionWindow.n-transforms", count},
                }
            end
        end,

        -- Defines AbstractGuiSelectionPanel.Title.
        Title = {"dana.apps.graph.selectionWindow.linkCategory"},
    },
}
MetaUtils.derive(AbstractGuiSelectionPanel.Metatable, Metatable)

-- Map[isFromRoot]: Map giving the color of the arrow for link selection.
LinkArrowColor = ErrorOnInvalidRead.new{
    [true] = {r = 1, g = 0.6, b = 0.6, a = 1},
    [false] = {r = 0.6, g = 1, b = 0.6, a = 1},
}

-- Map[isFromRoot]: LuaGuiElement construction info of the arrow for link selection.
LinkArrowLabel = ErrorOnInvalidRead.new{
    [true] = {
        type = "label",
        name = "arrowLabel",
        caption = "⟶",
        tooltip = {"dana.apps.graph.selectionWindow.ingredientLink"},
    },
    [false] = {
        type = "label",
        name = "arrowLabel",
        caption = "⟵",
        tooltip = {"dana.apps.graph.selectionWindow.productLink"},
    },
}

return GuiLinkSelectionPanel
