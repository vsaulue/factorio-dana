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

local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")
local LayerTreeLinkGenerator = require("lua/LayerTreeLinkGenerator")
local LayoutCoordinates = require("lua/LayoutCoordinates")
local Logger = require("lua/Logger")

-- Helper class to compute the final coordinates of a LayerLayout object.
--
-- This class is private (not accessible from other files): it is just an intermediate
-- used during the layout generation.
--
-- Fields:
-- * entryPositions[type][index]: Placement data of the entry with the given type & index.
-- * layout: Input LayerLayout instance.
-- * result: Output LayoutCoordinates object.
--
local LayerCoordinateGenerator = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Computes the coordinates of each elements of a LayerLayout object.
--
-- Args:
-- * layout: LayerLayout object.
-- * params: LayoutParameters object, describing constraints for the coordinates of elements.
--
-- Returns: a LayoutCoordinates object.
--
function LayerCoordinateGenerator.run(layout, params)
    local result = LayoutCoordinates.new()
    local self = ErrorOnInvalidRead.new{
        entryPositions = ErrorOnInvalidRead.new{
            edge = result.edges,
            linkNode = ErrorOnInvalidRead.new(),
            vertex = result.vertices,
        },
        layout = layout,
        result = result,
    }
    local typeToMinX = ErrorOnInvalidRead.new{
        edge = params.edgeMinX,
        linkNode = params.linkWidth,
        vertex = params.vertexMinX,
    }
    local typeToMarginX = ErrorOnInvalidRead.new{
        edge = params.edgeMarginX,
        linkNode = 0,
        vertex = params.vertexMarginX,
    }
    local typeToMinY = ErrorOnInvalidRead.new{
        edge = params.edgeMinY,
        linkNode = math.max(params.edgeMinY, params.vertexMinY),
        vertex = params.vertexMinY,
    }
    local yLayerLength = math.max(
        params.edgeMinY + 2 * params.edgeMarginY,
        params.vertexMinY + 2 * params.vertexMarginY
    )
    local middleY = yLayerLength / 2
    for layerId=1,layout.layers.entries.count do
        local layer = layout.layers.entries[layerId]
        local x = 0
        for rank=1,layer.count do
            local entry = layer[rank]
            local entryType = entry.type
            local xLength = typeToMinX[entryType]
            local xMargin = typeToMarginX[entryType]
            x = x + xMargin
            local yHalfLength = typeToMinY[entryType] / 2
            self.entryPositions[entry.type][entry.index] = ErrorOnInvalidRead.new{
                xMin = x,
                xMax = x + xLength,
                yMin = middleY - yHalfLength,
                yMax = middleY + yHalfLength,
            }
            x = x + xLength + xMargin
        end
        middleY = middleY + 4 * yLayerLength
    end
    for _,pos in pairs(layout.layers.reverse.vertex) do
        local vertexEntry = layout.layers.entries[pos[1]][pos[2]]
        LayerTreeLinkGenerator.run(self, vertexEntry)
    end
    return result
end

return LayerCoordinateGenerator
