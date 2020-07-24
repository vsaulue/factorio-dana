-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local CircleNodeShape = require("lua/layouts/CircleNodeShape")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayoutParameters = require("lua/layouts/LayoutParameters")
local RectangleNodeShape = require("lua/layouts/RectangleNodeShape")

-- A set of constants used to configure the SimpleRenderer.
local SimpleConfig = ErrorOnInvalidRead.new{
    -- Color of the edge nodes.
    EdgeColor = {a = 1, r = 0.1, g = 0.1, b = 0.1},

    -- Color of the frame of the legend.
    LegendFrameColor = {a=1,r=0.8,g=0.8,b=0.8},

    -- Color of the text in the legend.
    LegendTextColor = {a=1,r=0.8,g=0.8,b=0.8},

    -- Map[categoryIndex] -> Color, used to determine the color of the links.
    LinkCategoryToColor = ErrorOnInvalidRead.new{
        ["layer.forward"] = {r = 1, g = 1, b = 1, a = 1},
        ["layer.backward"] = {a = 1, r = 1},
    },

    -- Width (in pixels) of the lines used to draw links.
    LinkLineWitdh = 1,

    -- LayoutParameters defining the shapes/dimensions of elements in the drawing.
    LayoutParameters = LayoutParameters.new{
        edgeShape = RectangleNodeShape.new{
            xMargin = 0.2,
            yMargin = 0.2,
            minXLength = 1.6,
            minYLength = 1.6,
        },
        linkWidth = 0.25,
        vertexShape = CircleNodeShape.new{
            minRadius = 0.8,
            xMargin = 0.2,
            yMargin = 0.2,
        },
    },

    -- Color of the vertex nodes.
    VertexColor = {a = 1, r = 0.2, g = 0.2, b = 0.2},
}

return SimpleConfig
