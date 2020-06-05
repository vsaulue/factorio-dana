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
local ChannelLayer = require("lua/layouts/layer/ChannelLayer")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Layers = require("lua/layouts/layer/Layers")

-- Class wraping a Layers object, adding useful intermediates for layer sorting algorithms.
--
-- RO fields:
-- * layers: Layer object being built.
-- * linkNodes[channelIndex,layerIndex]: map giving the vertex/linkNode entry for the specified channel in the specified layer.
--
-- Methods:
-- * generateChannelLayers: Generates the channel layers for this layer layout.
-- * newEdge: Adds a new hyperedge from the input hypergraph to a Layers object.
-- * newVertex: Adds a new vertex from the input hypergraph to a Layers object.
--
local LayersBuilder = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

local Impl = ErrorOnInvalidRead.new{
    initLinkNodes = nil, -- implemented later

    link = nil, -- implemented later

    -- Metatable of the LayersBuilder class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            generateChannelLayers = nil, -- implemented later

            newEdge = nil, -- implemented later

            newVertex = nil, -- implemented later
        },
    },

    newEntry = nil, -- implemented later

    newHorizontalLink = nil, -- implemented later

    newLinkNode = nil, -- implemented later

    newVerticalLink = nil, -- implemented later

    newVerticalLink2 = nil, -- implemented later
}

-- Adds a new set in the `linkNodes` field for the specified channel index.
--
-- Args:
-- * self: LayersBuilder object.
-- * vertexIndex: Value of the vertexIndex field of the ChannelIndex.
-- * isForward: Value of the isForward field of the ChannelIndex.
-- * isFromVertexToEdge: Value of the isFromVertexToEdge field of the ChannelIndex.
-- * value: Set to add in `self.linkNodes` (or nil for an empty set).
--
function Impl.initLinkNodes(self, vertexIndex, isForward, isFromVertexToEdge, value)
    local channelIndex = self.channelIndexFactory:get(vertexIndex, isForward, isFromVertexToEdge)
    self.linkNodes[channelIndex] = value or {}
end

-- Creates a sequence of links & linkNode entries between a vertex and an edge.
--
-- Args:
-- * self: LayersBuilder object.
-- * edgeEntry: Entry of the edge to link.
-- * vertexEntry: Entry of the vertex to link.
-- * isFromVertexToEdge: true if the link goes from the vertex to the edge, false for the other way.
--
function Impl.link(self, edgeEntry, vertexEntry, isFromVertexToEdge)
    local edgeLayerId = self.layers:getPos(edgeEntry)[1]
    local vertexLayerId = self.layers:getPos(vertexEntry)[1]

    local isForward = false
    local step = -1
    local newVerticalLink = Impl.newVerticalLink
    if edgeLayerId < vertexLayerId then
        step = 1
        isForward = not isFromVertexToEdge
        newVerticalLink = Impl.newVerticalLink2
    elseif edgeLayerId > vertexLayerId then
        isForward = isFromVertexToEdge
    end

    local channelIndex = self.channelIndexFactory:get(vertexEntry.index, isForward, isFromVertexToEdge)
    local linkNodes = self.linkNodes[channelIndex]

    -- Horizontal connections.
    local previousEntry = edgeEntry
    if not isForward then
        local linkNode = linkNodes[vertexLayerId]
        if not linkNode then
            linkNode = Impl.newLinkNode(self, vertexLayerId, channelIndex)
        end
        Impl.newHorizontalLink(self, linkNode, vertexEntry, channelIndex, not isFromVertexToEdge)

        linkNode = linkNodes[edgeLayerId]
        if not linkNode then
            linkNode = Impl.newLinkNode(self, edgeLayerId, channelIndex)
        end
        Impl.newHorizontalLink(self, linkNode, edgeEntry, channelIndex, isFromVertexToEdge)
        previousEntry = linkNode
    end

    -- Vertical connections.
    local i = edgeLayerId + step
    local connected = (edgeLayerId == vertexLayerId)
    while not connected do
        local linkNode = linkNodes[i]
        if linkNode then
            newVerticalLink(self, linkNode, previousEntry, channelIndex)
            connected = true
        else
            linkNode = Impl.newLinkNode(self, i, channelIndex)
            i = i + step
            newVerticalLink(self, linkNode, previousEntry, channelIndex)
            previousEntry = linkNode
        end
    end
end

-- Generates the channel layers for this layer layout.
--
-- N+1 channel layers are generated (N being the number of entry layers). The first channel
-- layer returned by this function is placed before the first entry layer. The last channel
-- layer of the returned array is placed after the last entry layer.
--
-- Args:
-- * self: LayersBuilder object.
--
-- Returns: An array containing the generated channel layers.
--
function Impl.Metatable.__index.generateChannelLayers(self)
    local entries = self.layers.entries
    local result = Array.new()

    -- 1) Create N+1 channel layers.
    local count = entries.count + 1
    for i=1,count do
        result[i] = ChannelLayer.new()
    end
    result.count = count

    -- 2) Fill them.
    for i=1,entries.count do
        local layer = entries[i]
        local lowChannelLayer = result[i]
        local highChannelLayer = result[i+1]
        for j=1,layer.count do
            local entry = layer[j]
            local inboundSlots = entry.inboundSlots
            for i=1,inboundSlots.count do
                lowChannelLayer:appendHighEntry(inboundSlots[i], entry)
            end
            local outboundSlots = entry.outboundSlots
            for i=1,outboundSlots.count do
                highChannelLayer:appendLowEntry(outboundSlots[i], entry)
            end
        end
    end

    return result
end

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
function Impl.Metatable.__index.newEdge(self, layerIndex, edge)
    local edgeEntry = {
        type = "edge",
        index = edge.index,
    }
    Impl.newEntry(self, layerIndex, edgeEntry)

    for vertexIndex in pairs(edge.inbound) do
        local vertexEntry = self.layers:getEntry("vertex",vertexIndex)
        Impl.link(self, edgeEntry, vertexEntry, true)
    end

    for vertexIndex in pairs(edge.outbound) do
        local vertexEntry = self.layers:getEntry("vertex",vertexIndex)
        Impl.link(self, edgeEntry, vertexEntry, false)
    end
end

-- Adds a new vertex from the input hypergraph to a Layers object.
--
-- Args:
-- * self: LayersBuilder object.
-- * layerIndex: Index of the layer in which the vertex will be inserted.
-- * vertexIndex: Index of the vertex from the hypergraph.
--
function Impl.Metatable.__index.newVertex(self, layerIndex, vertexIndex)
    local newEntry = Impl.newEntry(self, layerIndex, {
        type = "vertex",
        index = vertexIndex,
    })

    Impl.initLinkNodes(self, vertexIndex, true, false, {
        [layerIndex] = newEntry,
    })
    Impl.initLinkNodes(self, vertexIndex, true, true, {
        [layerIndex] = newEntry,
    })
    Impl.initLinkNodes(self, vertexIndex, false, false)

    -- Current layer assignation never produce backward & 'vertex -> edge' links.
    -- Impl.initLinkNodes(self, vertexIndex, false, true)
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
function Impl.newEntry(self, layerIndex, newEntry)
    self.layers:newEntry(layerIndex, newEntry)
    return newEntry
end

-- Connects two entries in the same layer through the specified channel index.
--
-- Args:
-- * self: LayersBuilder object.
-- * entryA: One of the entry to connect.
-- * entryB: The other entry to connect.
-- * channelIndex: ChannelIndex of this link.
-- * isLow: True to make the connection in the lower channel layer, false for the upper channel layer.
--
function Impl.newHorizontalLink(self, entryA, entryB, channelIndex, isLow)
    assert(self.layers:getPos(entryA)[1] == self.layers:getPos(entryA)[1], "LayerLayout: invalid link creation.")

    local slotTableName = "outboundSlots"
    if isLow then
        slotTableName = "inboundSlots"
    end

    entryA[slotTableName]:pushBackIfNotPresent(channelIndex)
    entryB[slotTableName]:pushBackIfNotPresent(channelIndex)
end

-- Creates a new linkNode.
--
-- Args:
-- * self: LayersBuilder object.
-- * layerId: Index of the layer in which the entry will be inserted.
-- * channelIndex: ChannelIndex of the new linkNode entry.
--
-- Returns: The new linkNode entry.
--
function Impl.newLinkNode(self, layerId, channelIndex)
    local linkNodes = self.linkNodes[channelIndex]
    assert(not linkNodes[layerId], "LayersBuilder: attempt to override a linkNode entry.")
    local result = Impl.newEntry(self, layerId, {
        type = "linkNode",
        index = {},
    })
    linkNodes[layerId] = result
    return result
end

-- Connects two entries from different layers through the specified channel index.
--
-- Args:
-- * self: LayersBuilder object.
-- * lowEntry: Entry with the lowest layerId to connect.
-- * highEntry: Entry with the greatest layerId to connect.
-- * channelIndex: ChannelIndex of this link.
--
function Impl.newVerticalLink(self, lowEntry, highEntry, channelIndex)
    local reverse = self.layers.reverse
    assert(reverse[lowEntry.type][lowEntry.index][1] == reverse[highEntry.type][highEntry.index][1] - 1, "LayerLayout: invalid link creation.")
    lowEntry.outboundSlots:pushBackIfNotPresent(channelIndex)
    highEntry.inboundSlots:pushBackIfNotPresent(channelIndex)
end

-- Connects two entries from different layers through the specified channel index.
--
-- Args:
-- * self: LayersBuilder object.
-- * highEntry: Entry with the greatest layerId to connect.
-- * lowEntry: Entry with the lowest layerId to connect.
-- * channelIndex: ChannelIndex of this link.
--
function Impl.newVerticalLink2(self, highEntry, lowEntry, channelIndex)
    Impl.newVerticalLink(self, lowEntry, highEntry, channelIndex)
end

-- Creates a new LayersBuilder object.
--
-- Args:
-- * object: Table to turn into a LayersBuilder object (must have a channelIndexFactory field).
--
-- Returns: The new LayersBuilder object.
--
function LayersBuilder.new(object)
    assert(not object.layers, "LayersBuilder: 'layers' field in constructor forbidden.")
    assert(object.channelIndexFactory, "LayersBuilder: missing mandatory 'channelIndexFactory' field in constructor.")

    object.layers = Layers.new()
    object.linkNodes = ErrorOnInvalidRead.new()

    setmetatable(object, Impl.Metatable)

    return object
end

return LayersBuilder
