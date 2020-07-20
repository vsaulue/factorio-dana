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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

-- Helper library to assign an X coordinate to entries in LayerCoordinateGenerator.
--
local LayerXPass = ErrorOnInvalidRead.new{
    -- Computes the X coordinate of all entries.
    --
    -- Args:
    -- * self: LayerCoordinateGenerator object.
    --
    run = function(layerCoordinateGenerator)
        local params = layerCoordinateGenerator.params
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
        local entries = layerCoordinateGenerator.layout.layers.entries
        local xLengthMax = - math.huge
        local layerXLengths = ErrorOnInvalidRead.new()
        for layerId=1,entries.count do
            local layer = entries[layerId]
            local x = 0
            for rank=1,layer.count do
                local entry = layer[rank]
                local entryType = entry.type
                local maxSlotsCount = math.max(entry.lowSlots.count, entry.highSlots.count)
                local xLength = math.max(typeToMinX[entryType], params.linkWidth * maxSlotsCount)
                local xMargin = typeToMarginX[entryType]
                x = x + xMargin
                local entryRecord = layerCoordinateGenerator.entryPositions[entry]
                entryRecord:initX(x, xLength, xMargin)
                x = x + xLength + xMargin
            end
            if x > xLengthMax then
                xLengthMax = x
            end
            layerXLengths[layerId] = x
        end

        -- Center
        for layerId=1,entries.count do
            local layer = entries[layerId]
            local xDelta = (xLengthMax - layerXLengths[layerId]) / 2
            for rank=1,layer.count do
                layerCoordinateGenerator.entryPositions[layer[rank]]:translateX(xDelta)
            end
        end
    end,
}

return LayerXPass
