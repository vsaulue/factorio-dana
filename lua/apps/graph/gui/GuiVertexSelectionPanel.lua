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
local GuiSelectionConstants = require("lua/apps/graph/gui/GuiSelectionConstants")
local MetaUtils = require("lua/class/MetaUtils")

local Metatable

-- Instanciated GUI of an VertexSelectionPanel.
--
-- Inherits from AbstractGuiSelectionPanel.
--
-- RO Fields:
-- * controller (override): VertexSelectionPanel.
--
local GuiVertexSelectionPanel = ErrorOnInvalidRead.new{
    -- Creates a new GuiVertexSelectionPanel object.
    --
    -- RO Fields:
    -- * object: table. Required fields: see AbstractGuiSelectionPanel.new().
    --
    -- Returns: GuiVertexSelectionPanel. The `object` argument turned into the desired type.
    --
    new = function(object)
        return AbstractGuiSelectionPanel.new(object, Metatable)
    end,

    -- Restores the metatable of an GuiVertexSelectionPanel, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        AbstractGuiSelectionPanel.setmetatable(object, Metatable)
    end,
}

-- Metatable of the GuiVertexSelectionPanel class.
Metatable = {
    __index = {
        -- Implements AbstractGuiSelectionPanel.makeElementGui().
        --
        -- Args:
        -- * parent: LuaGuiElement.
        -- * prepNodeIndex: PrepNodeIndex.
        --
        makeElementGui = function(parent, prepNodeIndex)
            local vertexIndex = prepNodeIndex.index
            local elemFlow = GuiMaker.run(parent, {
                type = "flow",
                direction = "horizontal",
                children = {
                    GuiSelectionConstants.VertexTypeIcon[vertexIndex.type],
                    {
                        type = "sprite",
                        name = "vertexIcon",
                        sprite = vertexIndex.spritePath,
                    },{
                        type = "label",
                        caption = vertexIndex.rawPrototype.localised_name,
                    },
                },
            })
            elemFlow.vertexTypeIcon.style.minimal_width = 32
            elemFlow.vertexIcon.style.minimal_width = 32
        end,

        -- Defines AbstractGuiSelectionPanel.Title.
        Title = {"dana.apps.graph.selectionWindow.vertexCategory"}
    },
}
MetaUtils.derive(AbstractGuiSelectionPanel.Metatable, Metatable)

return GuiVertexSelectionPanel
