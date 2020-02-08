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
local Layers = require("lua/layouts/layer/Layers")
local LayerLink = require("lua/layouts/layer/LayerLink")

-- Class wraping a Layers object, adding useful intermediates for layer sorting algorithms.
--
-- RO fields:
-- * layers: Layer object being built.
-- * links.backward[someEntry]: set of LayerLink in which someEntry is the greatest layerId end.
-- * links.forward[someEntry]: set of LayerLink in which someEntry is the lowest layerId end.
-- * linkNodes[channelIndex,layerIndex]: map giving the vertex/linkNode entry for the specified channel in the specified layer.
--
-- Methods:
-- * newEdge: Adds a new hyperedge from the input hypergraph to a Layers object.
-- * newVertex: Adds a new vertex from the input hypergraph to a Layers object.
--
local LayersBuilder = ErrorOnInvalidRead.new{
    new = nil, -- implemented later
}

local Impl = ErrorOnInvalidRead.new{
    link = nil, -- implemented later

    -- Metatable of the LayersBuilder class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            newEdge = nil, -- implemented later

            newVertex = nil, -- implemented later
        },
    },

    newEntry = nil, -- implemented later

    newLink = nil, -- implemented later

    newLink2 = nil, -- implemented later
}

-- Creates a sequence of links & linkNode entries between a vertex and an edge.
--
-- Args:
-- * self: LayersBuilder object.
-- * edgeEntry: Entry of the edge to link.
-- * vertexEntry: Entry of the vertex to link.
-- * isFromVertexToEdge: true if the link goes from the vertex to the edge, false for the other way.
--
function Impl.link(self, edgeEntry, vertexEntry, isFromVertexToEdge)
    local edgePos = self.layers.reverse[edgeEntry.type][edgeEntry.index]
    local vertexPos = self.layers.reverse[vertexEntry.type][vertexEntry.index]

    local edgeLayerId = edgePos[1]
    local vertexLayerId = vertexPos[1]
    -- Default values: edgePos[1] >= vertexPos[1]
    local step = -1
    local isForward = isFromVertexToEdge
    local newLink = Impl.newLink
    if edgeLayerId < vertexLayerId then
        step = 1
        isForward = not isFromVertexToEdge
        newLink = Impl.newLink2
    end

    local channelIndex = self.channelIndexFactory:get(vertexEntry.index, isForward)
    local linkNodes = self.linkNodes[channelIndex]

    local i = edgeLayerId + step
    local previousEntry = edgeEntry
    local connected = false
    while not connected do
        local linkNode = linkNodes[i]
        if linkNode then
            newLink(self, linkNode, previousEntry, channelIndex)
            connected = true
        else
            local entry = {
                type = "linkNode",
                index = {},
            }
            Impl.newEntry(self, i, entry)
            linkNodes[i] = entry
            i = i + step
            newLink(self, entry, previousEntry, channelIndex)
            previousEntry = entry
        end
    end
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

    for _,vertexIndex in pairs(edge.inbound) do
        local vertexEntry = self.layers:getEntry("vertex",vertexIndex)
        Impl.link(self, edgeEntry, vertexEntry, true)
    end

    for _,vertexIndex in pairs(edge.outbound) do
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
    local channelFactory = self.channelIndexFactory
    local linkNodes = self.linkNodes
    local forwardIndex = channelFactory:get(vertexIndex, true)
    linkNodes[forwardIndex] = { [layerIndex] = newEntry }
    local backwardIndex = channelFactory:get(vertexIndex, false)
    linkNodes[backwardIndex] = { [layerIndex] = newEntry }
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
    self.links.backward[newEntry] = ErrorOnInvalidRead.new()
    self.links.forward[newEntry] = ErrorOnInvalidRead.new()
    return newEntry
end

-- Creates a new link.
--
-- Args:
-- * self: LayersBuilder object.
-- * lowEntry: Entry with the lowest layerId to link.
-- * highEntry: Entry with the greatest layerId to link.
-- * channelIndex: ChannelIndex of this link.
--
function Impl.newLink(self, lowEntry, highEntry, channelIndex)
    local reverse = self.layers.reverse
    assert(reverse[lowEntry.type][lowEntry.index][1] == reverse[highEntry.type][highEntry.index][1] - 1, "LayerLayout: invalid link creation.")
    local newLink = LayerLink.new(lowEntry, highEntry, channelIndex)
    lowEntry.outboundSlots:pushBackIfNotPresent(channelIndex)
    highEntry.inboundSlots:pushBackIfNotPresent(channelIndex)
    self.links.backward[highEntry][newLink] = true
    self.links.forward[lowEntry][newLink] = true
end

-- Creates a new link.
--
-- Args:
-- * self: LayersBuilder object.
-- * highEntry: Entry with the greatest layerId to link.
-- * lowEntry: Entry with the lowest layerId to link.
-- * channelIndex: ChannelIndex of this link.
--
function Impl.newLink2(self, highEntry, lowEntry, channelIndex)
    Impl.newLink(self, lowEntry, highEntry, channelIndex)
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
    object.links = ErrorOnInvalidRead.new{
        forward = ErrorOnInvalidRead.new(),
        backward = ErrorOnInvalidRead.new(),
    }
    object.linkNodes = ErrorOnInvalidRead.new()

    setmetatable(object, Impl.Metatable)

    return object
end

return LayersBuilder