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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ClassLogger = require("lua/logger/ClassLogger")
local LayerLinkIndex = require("lua/layouts/layer/LayerLinkIndex")

local cLogger = ClassLogger.new{className = "LayerLinkBuilder"}

local addLinkIndex
local getLayerIdAndEntry
local newLayerLinkIndex

-- Utility library to build links into a Layers object.
--
local LayerLinkBuilder = ErrorOnInvalidRead.new{
    -- Includes all the links of an hypergraph into a Layers object.
    --
    -- All edges & vertices must have been placed in the Layers object beforehand.
    --
    -- Args:
    -- * layerLayout: LayerLayout object being built.
    --
    run = function(layerLayout)
        local layers = layerLayout.layers
        local graph = layerLayout.prepGraph
        local reverse = layers.reverse
        for linkIndex,leaves in pairs(graph.links) do
            local rLayerId,rEntry = getLayerIdAndEntry(layers, linkIndex.rootNodeIndex)

            local forwardIndex = nil
            local backwardIndex = nil
            local lMin = math.huge
            local lMax = -math.huge
            if linkIndex.isFromRoot then
                for leafIndex in pairs(leaves) do
                    local lLayerId,lEntry = getLayerIdAndEntry(layers, leafIndex)

                    if lLayerId > rLayerId then
                        forwardIndex = forwardIndex or newLayerLinkIndex(linkIndex, true)
                        lEntry.lowSlots:pushBack(forwardIndex)
                        lMax = math.max(lMax, lLayerId)
                    else
                        backwardIndex = backwardIndex or newLayerLinkIndex(linkIndex, false)
                        lEntry.lowSlots:pushBack(backwardIndex)
                        lMin = math.min(lMin, lLayerId)
                    end
                end

                addLinkIndex(layerLayout, rEntry.highSlots, forwardIndex , 1 + rLayerId, lMax - 1)
                addLinkIndex(layerLayout, rEntry.highSlots, backwardIndex, lMin        , rLayerId)
            else
                for leafIndex in pairs(leaves) do
                    local lLayerId,lEntry = getLayerIdAndEntry(layers, leafIndex)

                    if lLayerId < rLayerId then
                        forwardIndex = forwardIndex or newLayerLinkIndex(linkIndex, true)
                        lEntry.highSlots:pushBack(forwardIndex)
                        lMin = math.min(lMin, lLayerId)
                    else
                        backwardIndex = backwardIndex or newLayerLinkIndex(linkIndex, false)
                        lEntry.highSlots:pushBack(backwardIndex)
                        lMax = math.max(lMax, lLayerId)
                    end
                end

                addLinkIndex(layerLayout, rEntry.lowSlots, forwardIndex , 1 + lMin, rLayerId - 1)
                addLinkIndex(layerLayout, rEntry.lowSlots, backwardIndex, rLayerId, lMax)
            end
        end
    end,
}

-- Finalize the addition of a LayerLinkIndex.
--
-- Args:
-- * layerLayout: LayerLayout object.
-- * rootSlots: Slots of the root's entry to fill.
-- * linkIndex: LayerLinkIndex to finalize (may be nil: in this case the function does nothing).
-- * lowLayerId: First index of the range of layers for which a linkNode must be added.
-- * highLayerId: Last index of the range of layers for which a linkNode must be added.
--
addLinkIndex = function(layerLayout, rootSlots, linkIndex, lowLayerId, highLayerId)
    if linkIndex then
        rootSlots:pushBack(linkIndex)
        layerLayout.linkIndices[linkIndex] = true
        for layerId=lowLayerId,highLayerId do
            local linkNode = {
                type = "linkNode",
                index = {},
            }
            layerLayout.layers:newEntry(layerId, linkNode)
            linkNode.lowSlots:pushBack(linkIndex)
            linkNode.highSlots:pushBack(linkIndex)
        end
    end
end

-- Gets the layer index and entry of a PrepNodeIndex in a Layers object.
--
-- Args:
-- * layers: Layers object containing the entry.
-- * nodeIndex: PrepNodeIndex to look for.
--
-- Returns:
-- * The index of the layer of the associated entry.
-- * The associated entry.
--
getLayerIdAndEntry = function(layers, nodeIndex)
    local pos = layers.reverse.node[nodeIndex]
    local layerId = pos[1]
    local entry = layers.entries[layerId][pos[2]]
    return layerId,entry
end

-- Creates a new LayerLinkIndex object.
--
-- Args:
-- * linkIndex: LinkIndex to copy.
-- * isForward: isForward field value.
--
-- Returns: The new LayerLinkIndex object.
--
newLayerLinkIndex = function(linkIndex, isForward)
    return LayerLinkIndex.new{
        isForward = isForward,
        isFromRoot = linkIndex.isFromRoot,
        rootNodeIndex = linkIndex.rootNodeIndex,
        symbol = linkIndex.symbol,
    }
end

return LayerLinkBuilder
