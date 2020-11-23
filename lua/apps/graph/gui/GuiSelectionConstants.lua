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

local BoilerTransform = require("lua/model/BoilerTransform")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local FuelTransform = require("lua/model/FuelTransform")
local Intermediate = require("lua/model/Intermediate")
local RecipeTransform = require("lua/model/RecipeTransform")

-- Some constants for the SelectionWindow & panels.
local GuiSelectionConstants = ErrorOnInvalidRead.new{
    -- Map[AbstractTransform.type]: table. GUI constructor arguments for a sprite representing a transform type.
    EdgeTypeIcon = ErrorOnInvalidRead.new{
        boiler = {
            type = "sprite",
            name = "edgeTypeIcon",
            sprite = "dana-boiler-icon",
            tooltip = BoilerTransform.TypeLocalisedStr,
        },
        fuel = {
            type = "sprite",
            name = "edgeTypeIcon",
            sprite = "dana-fuel-icon",
            tooltip = FuelTransform.TypeLocalisedStr,
        },
        recipe = {
            type = "sprite",
            name = "edgeTypeIcon",
            sprite = "dana-recipe-icon",
            tooltip = RecipeTransform.TypeLocalisedStr,
        },
    },

    -- Map[Intermediate.type]: table. GUI constructor arguments for a sprite representing an intermediate type.
    VertexTypeIcon = ErrorOnInvalidRead.new{
        fluid = {
            type = "sprite",
            name = "vertexTypeIcon",
            sprite = "dana-fluid-icon",
            tooltip = Intermediate.TypeToLocalisedStr.fluid,
        },
        item = {
            type = "sprite",
            name = "vertexTypeIcon",
            sprite = "dana-item-icon",
            tooltip = Intermediate.TypeToLocalisedStr.item,
        },
    },
}

return GuiSelectionConstants
