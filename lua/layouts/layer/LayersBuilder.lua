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

local Array = require("lua/containers/Array")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Layers = require("lua/layouts/layer/Layers")

local cLogger = ClassLogger.new{className = "LayersBuilder"}

local initLinkNodes
local link
local Metatable
local newEntry
local newHorizontalLink
local newLinkNode
local newVerticalLink
local newVerticalLink2

-- Class wraping a Layers object, adding useful intermediates for layer sorting algorithms.
--
-- RO fields:
-- * layers: Layer object being built.
-- * linkNodes[linkIndex,layerIndex]: map giving the vertex/linkNode entry for the specified link in the specified layer.
--
-- Methods: see Metatable.__index.
--
local LayersBuilder = ErrorOnInvalidRead.new{
    -- Creates a new LayersBuilder object.
    --
    -- Args:
    -- * object: Table to turn into a LayersBuilder object (must have a linkIndexFactory field).
    --
    -- Returns: The new LayersBuilder object.
    --
    new = function(object)
        cLogger:assertField(object, "linkIndexFactory")

        object.layers = Layers.new()
        object.linkNodes = ErrorOnInvalidRead.new()

        setmetatable(object, Metatable)

        return object
    end,
}

-- Metatable of the LayersBuilder class.
Metatable = {
    __index = ErrorOnInvalidRead.new{

        -- Adds a new hyperedge from the input hypergraph to a Layers object.
        --
        -- This function will create a new entry of type "edge" into the Layers object, and links
        -- between the vertices and this entry. It will also add intermediate "linkNode" entries to
        -- ensure no link crosses multiple layers.
        --
        -- It will try to reuse "linkNode" entries: in a given layer, there is at most 2 "linkNode" entries
        -- for each vertexIndex: one for forward links, one for backward links.
        --
        -- Args:
        -- * self: LayersBuilder object.
        -- * layerIndex: Index of the layer in which the vertex will be inserted.
        -- * edge: Edge from the input hypergraph to add.
        --
        newEdge = function(self, layerIndex, edge)
            local edgeEntry = {
                type = "edge",
                index = edge.index,
            }
            newEntry(self, layerIndex, edgeEntry)

            for vertexIndex in pairs(edge.inbound) do
                local vertexEntry = self.layers:getEntry("vertex",vertexIndex)
                link(self, edgeEntry, vertexEntry, true)
            end

            for vertexIndex in pairs(edge.outbound) do
                local vertexEntry = self.layers:getEntry("vertex",vertexIndex)
                link(self, edgeEntry, vertexEntry, false)
            end
        end,

        -- Adds a new vertex from the input hypergraph to a Layers object.
        --
        -- Args:
        -- * self: LayersBuilder object.
        -- * layerIndex: Index of the layer in which the vertex will be inserted.
        -- * vertexIndex: Index of the vertex from the hypergraph.
        --
        newVertex = function(self, layerIndex, vertexIndex)
            local newEntry = newEntry(self, layerIndex, {
                type = "vertex",
                index = vertexIndex,
            })

            initLinkNodes(self, vertexIndex, true, false, {
                [layerIndex] = newEntry,
            })
            initLinkNodes(self, vertexIndex, true, true, {
                [layerIndex] = newEntry,
            })
            initLinkNodes(self, vertexIndex, false, false)

            -- Current layer assignation never produce backward & 'vertex -> edge' links.
            -- initLinkNodes(self, vertexIndex, false, true)
        end,
    },
}

-- Adds a new set in the `linkNodes` field for the specified LinkIndex.
--
-- Args:
-- * self: LayersBuilder object.
-- * vertexIndex: Value of the vertexIndex field of the LinkIndex.
-- * isForward: Value of the isForward field of the LinkIndex.
-- * isFromRoot: Value of the isFromRoot field of the LinkIndex.
-- * value: Set to add in `self.linkNodes` (or nil for an empty set).
--
initLinkNodes = function(self, vertexIndex, isForward, isFromRoot, value)
    local linkIndex = self.linkIndexFactory:get(vertexIndex, isForward, isFromRoot)
    self.linkNodes[linkIndex] = value or {}
end

-- Creates a sequence of links & linkNode entries between a vertex and an edge.
--
-- Args:
-- * self: LayersBuilder object.
-- * edgeEntry: Entry of the edge to link.
-- * vertexEntry: Entry of the vertex to link.
-- * isFromRoot: true if the link goes from the vertex to the edge, false for the other way.
--
link = function(self, edgeEntry, vertexEntry, isFromRoot)
    local edgeLayerId = self.layers:getPos(edgeEntry)[1]
    local vertexLayerId = self.layers:getPos(vertexEntry)[1]

    local isForward = false
    local step = -1
    local newVerticalLink = newVerticalLink
    if edgeLayerId < vertexLayerId then
        step = 1
        isForward = not isFromRoot
        newVerticalLink = newVerticalLink2
    elseif edgeLayerId > vertexLayerId then
        isForward = isFromRoot
    end

    local linkIndex = self.linkIndexFactory:get(vertexEntry.index, isForward, isFromRoot)
    local linkNodes = self.linkNodes[linkIndex]

    -- Horizontal connections.
    local previousEntry = edgeEntry
    if not isForward then
        local linkNode = linkNodes[vertexLayerId]
        if not linkNode then
            linkNode = newLinkNode(self, vertexLayerId, linkIndex)
        end
        newHorizontalLink(self, linkNode, vertexEntry, linkIndex, not isFromRoot)

        linkNode = linkNodes[edgeLayerId]
        if not linkNode then
            linkNode = newLinkNode(self, edgeLayerId, linkIndex)
        end
        newHorizontalLink(self, linkNode, edgeEntry, linkIndex, isFromRoot)
        previousEntry = linkNode
    end

    -- Vertical connections.
    local i = edgeLayerId + step
    local connected = (edgeLayerId == vertexLayerId)
    while not connected do
        local linkNode = linkNodes[i]
        if linkNode then
            newVerticalLink(self, linkNode, previousEntry, linkIndex)
            connected = true
        else
            linkNode = newLinkNode(self, i, linkIndex)
            i = i + step
            newVerticalLink(self, linkNode, previousEntry, linkIndex)
            previousEntry = linkNode
        end
    end
end

-- Adds a new entry to this layout.
--
-- Args:
-- * self: Layers object.
-- * layerIndex: Index of the layer in which the entry will be inserted.
-- * newEntry: Constructor argument for the new LayerEntry.
--
-- Returns: newEntry.
--
newEntry = function(self, layerIndex, newEntry)
    self.layers:newEntry(layerIndex, newEntry)
    return newEntry
end

-- Connects two entries in the same layer through the specified LinkIndex.
--
-- Args:
-- * self: LayersBuilder object.
-- * entryA: One of the entry to connect.
-- * entryB: The other entry to connect.
-- * linkIndex: LinkIndex of this link.
-- * isLow: True to make the connection in the lower channel layer, false for the upper channel layer.
--
newHorizontalLink = function(self, entryA, entryB, linkIndex, isLow)
    cLogger:assert(self.layers:getPos(entryA)[1] == self.layers:getPos(entryA)[1], "invalid link creation.")

    local slotTableName = "highSlots"
    if isLow then
        slotTableName = "lowSlots"
    end

    entryA[slotTableName]:pushBackIfNotPresent(linkIndex)
    entryB[slotTableName]:pushBackIfNotPresent(linkIndex)
end

-- Creates a new linkNode.
--
-- Args:
-- * self: LayersBuilder object.
-- * layerId: Index of the layer in which the entry will be inserted.
-- * linkIndex: LinkIndex of the new linkNode entry.
--
-- Returns: The new linkNode entry.
--
newLinkNode = function(self, layerId, linkIndex)
    local linkNodes = self.linkNodes[linkIndex]
    cLogger:assert(not linkNodes[layerId], "attempt to override a linkNode entry.")
    local result = newEntry(self, layerId, {
        type = "linkNode",
        index = {},
    })
    linkNodes[layerId] = result
    return result
end

-- Connects two entries from different layers through the specified LinkIndex.
--
-- Args:
-- * self: LayersBuilder object.
-- * lowEntry: Entry with the lowest layerId to connect.
-- * highEntry: Entry with the greatest layerId to connect.
-- * linkIndex: LinkIndex of this link.
--
newVerticalLink = function(self, lowEntry, highEntry, linkIndex)
    local reverse = self.layers.reverse
    cLogger:assert(reverse[lowEntry.type][lowEntry.index][1] == reverse[highEntry.type][highEntry.index][1] - 1, "invalid link creation.")
    lowEntry.highSlots:pushBackIfNotPresent(linkIndex)
    highEntry.lowSlots:pushBackIfNotPresent(linkIndex)
end

-- Connects two entries from different layers through the specified LinkIndex.
--
-- Args:
-- * self: LayersBuilder object.
-- * highEntry: Entry with the greatest layerId to connect.
-- * lowEntry: Entry with the lowest layerId to connect.
-- * linkIndex: LinkIndex of this link.
--
newVerticalLink2 = function(self, highEntry, lowEntry, linkIndex)
    newVerticalLink(self, lowEntry, highEntry, linkIndex)
end

return LayersBuilder
