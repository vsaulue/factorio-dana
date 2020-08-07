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

local newLinkIndex
local makeLinkNode

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
        local graph = layerLayout.graph
        local reverse = layers.reverse
        for vertexIndex,vertex in pairs(graph.vertices) do
            local vPos = reverse.vertex[vertexIndex]
            local vLayerId = vPos[1]
            local vEntry = layers.entries[vLayerId][vPos[2]]

            -- Edge -> Vertex links.
            local forwardIndex = newLinkIndex(true, false, vertexIndex)
            local backwardIndex = newLinkIndex(false, false, vertexIndex)
            local eMin = math.huge
            local eMax = -math.huge
            for edgeIndex in pairs(vertex.inbound) do
                local ePos = reverse.edge[edgeIndex]
                local eLayerId = ePos[1]
                local eEntry = layers.entries[eLayerId][ePos[2]]

                if eLayerId < vLayerId then
                    eEntry.highSlots:pushBack(forwardIndex)
                    vEntry.lowSlots:pushBackIfNotPresent(forwardIndex)
                    eMin = math.min(eMin, eLayerId)
                else
                    eEntry.highSlots:pushBack(backwardIndex)
                    vEntry.lowSlots:pushBackIfNotPresent(backwardIndex)
                    eMax = math.max(eMax, eLayerId)
                end
            end
            makeLinkNodes(layers, backwardIndex, vLayerId, eMax)
            makeLinkNodes(layers, forwardIndex, eMin+1, vLayerId-1)

            -- Vertex -> Edge links.
            eMax = -math.huge
            forwardIndex = newLinkIndex(true, true, vertexIndex)
            for edgeIndex in pairs(vertex.outbound) do
                local ePos = reverse.edge[edgeIndex]
                local eLayerId = ePos[1]
                local eEntry = layers.entries[eLayerId][ePos[2]]

                cLogger:assert(eLayerId > vLayerId, "Invalid layer of edge relative to an inbound vertex.")
                eEntry.lowSlots:pushBack(forwardIndex)
                vEntry.highSlots:pushBackIfNotPresent(forwardIndex)
                eMax = math.max(eMax, eLayerId)
            end
            makeLinkNodes(layers, forwardIndex, vLayerId+1, eMax-1)
        end
    end,
}

-- Creates a new LayerLinkIndex object.
--
-- Args:
-- * isForward: isForward field value.
-- * isFromRoot: isFromRoot field value.
-- * symbol: symbol field value.
--
-- Returns: The new LayerLinkIndex object.
--
newLinkIndex = function(isForward, isFromRoot, symbol)
    return LayerLinkIndex.new{
        isForward = isForward,
        isFromRoot = isFromRoot,
        symbol = symbol,
    }
end

-- Creates multiple link nodes between the specified layers.
--
-- Args:
-- * layers: Layers object to edit.
-- * linkIndex: LayerLinkIndex of the link nodes.
-- * lowLayerId: First index of the range of layers to edit.
-- * highLayerId: Last index of the range of layers to edit.
--
makeLinkNodes = function(layers, linkIndex, lowLayerId, highLayerId)
    for layerId=lowLayerId,highLayerId do
        local linkNode = {
            type = "linkNode",
            index = {},
        }
        layers:newEntry(layerId, linkNode)
        linkNode.lowSlots:pushBack(linkIndex)
        linkNode.highSlots:pushBack(linkIndex)
    end
end

return LayerLinkBuilder
