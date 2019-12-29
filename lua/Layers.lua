-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local Array = require("lua/Array")
local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")
local LayerEntry = require("lua/LayerEntry")
local LayerLink = require("lua/LayerLink")

-- Class holding a layer graph representation.
--
-- For an entry, {type,index} acts as a primary key: duplicates are forbidden.
--
-- RO fields:
-- * entries[layerId,rankInLayer]: 2-dim Array of LayerEntry, representing the layers.
-- * links.backward[someEntry]: set of LayerLink in which someEntry is the greatest layerId end.
-- * links.forward[someEntry]: set of LayerLink in which someEntry is the lowest layerId end.
-- * linkNodes[channelIndex,layerIndex]: map giving the vertex/linkNode entry for the specified channel in the specified layer.
-- * reverse[type,index]: 2-dim array giving coordinates from keys (reverse of entries).
--
-- Methods:
-- * getEntry: Gets an entry from its type and index.
-- * newEdge: Creates a new edge.
-- * newVertex: Creates a new vertex.
--
local Layers = {
    new = nil,
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the Layers class.
    Metatable = {
        __index = {
            -- Gets an entry from its type and index.
            --
            -- Args:
            -- * self: Layers object.
            -- * type: Type of the entry to look for.
            -- * index: Index of the entry to search.
            --
            -- Returns: The entry with the given index / type.
            --
            getEntry = function(self,type,index)
                local pos = self.reverse[type][index]
                return self.entries[pos[1]][pos[2]]
            end,

            newEdge = nil, -- implemented later

            newVertex = nil, -- implemented later

            -- Swaps 2 entries in a layer.
            --
            -- Args:
            -- * self: Layers object.
            -- * layerId: Index of the layer containing the entries.
            -- * x1: Rank of the 1st entry to swap.
            -- * x2: rank of the 2nd entry to swap.
            --
            swap = function(self, layerId, x1, x2)
                local layer = self.entries[layerId]
                local entry1 = layer[x1]
                local entry2 = layer[x2]
                layer[x1] = entry2
                layer[x2] = entry1
                self.reverse[entry1.type][entry1.index][2] = x2
                self.reverse[entry2.type][entry2.index][2] = x1
            end,

            -- Sorts a layer in place.
            --
            -- The layer is sorted from lower to higher weights.
            --
            -- Args:
            -- * self: Layers object.
            -- * layerId: Index of the layer to sort.
            -- * weights[entryId]: Map associating a weight to each entry of the sorted layer.
            --
            sortLayer = function(self, layerId, weights)
                local layer = self.entries[layerId]
                layer:sort(weights)
                for x=1,layer.count do
                    local entry = layer[x]
                    local position = self.reverse[entry.type][entry.index]
                    position[2] = x
                end
            end,
        },
    },

    link = nil, -- implemented later

    -- Adds a new entry to this layout.
    --
    -- Args:
    -- * self: Layers object.
    -- * layerIndex: Index of the layer in which the entry will be inserted.
    -- * entry: Constructor argument for the new LayerEntry.
    --
    newEntry = function(self,layerIndex,entry)
        local newEntry = LayerEntry.new(entry)
        assert(not rawget(self.reverse[newEntry.type], newEntry.index), "Layers: duplicate primary key.")
        self.links.backward[newEntry] = ErrorOnInvalidRead.new()
        self.links.forward[newEntry] = ErrorOnInvalidRead.new()
        if self.entries.count < layerIndex then
            for i=self.entries.count+1,layerIndex do
                self.entries[i] = Array.new()
            end
            self.entries.count = layerIndex
        end
        local layer = self.entries[layerIndex]
        layer:pushBack(newEntry)
        self.reverse[newEntry.type][newEntry.index] = {layerIndex, layer.count}
        return newEntry
    end,

    newLink = nil, -- implemented later

    newLink2 = nil, -- implemented later
}

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
-- * self: Layers object.
-- * layerIndex: Index of the layer in which the vertex will be inserted.
-- * edge: Edge from the input hypergraph to add.
--
function Impl.Metatable.__index.newEdge(self,layerIndex,edge)
    local edgeEntry = {
        type = "edge",
        index = edge.index,
    }
    Impl.newEntry(self, layerIndex, edgeEntry)

    for _,vertexIndex in pairs(edge.inbound) do
        local vertexEntry = self:getEntry("vertex",vertexIndex)
        Impl.link(self,edgeEntry, vertexEntry, true)
    end

    for _,vertexIndex in pairs(edge.outbound) do
        local vertexEntry = self:getEntry("vertex",vertexIndex)
        Impl.link(self,edgeEntry, vertexEntry, false)
    end
end

-- Adds a new vertex from the input hypergraph to a Layers object
--
-- Args:
-- * self: Layers object.
-- * layerIndex: Index of the layer in which the vertex will be inserted.
-- * vertexIndex: Index of the vertex from the hypergraph.
--
function Impl.Metatable.__index.newVertex(self,layerIndex,vertexIndex)
    local newEntry = Impl.newEntry(self,layerIndex,{
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

-- Creates a sequence of links & linkNode entries between a vertex and an edge.
--
-- Args:
-- * self: Layers object.
-- * edgeEntry: Entry of the edge to link.
-- * vertexEntry: Entry of the vertex to link.
-- * isFromVertexToEdge: true if the link goes from the vertex to the edge, false for the other way.
--
function Impl.link(self, edgeEntry, vertexEntry, isFromVertexToEdge)
    local edgePos = self.reverse[edgeEntry.type][edgeEntry.index]
    local vertexPos = self.reverse[vertexEntry.type][vertexEntry.index]

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
            newLink(self, linkNode, previousEntry, isForward)
            connected = true
        else
            local entry = {
                type = "linkNode",
                index = {},
                isForward = isForward,
            }
            Impl.newEntry(self, i, entry)
            linkNodes[i] = entry
            i = i + step
            newLink(self, entry, previousEntry, isForward)
            previousEntry = entry
        end
    end
end

-- Creates a new link.
--
-- Args:
-- * self: Layers object.
-- * lowEntry: Entry with the lowest layerId to link.
-- * highEntry: Entry with the greatest layerId to link.
-- * isForward: True if the link goes from lowEntry to highEntry, false otherwise.
--
function Impl.newLink(self,lowEntry,highEntry,isForward)
    assert(self.reverse[lowEntry.type][lowEntry.index][1] == self.reverse[highEntry.type][highEntry.index][1] - 1, "LayerLayout: invalid link creation.")
    local newLink = LayerLink.new(lowEntry, highEntry, isForward)
    self.links.backward[highEntry][newLink] = true
    self.links.forward[lowEntry][newLink] = true
end

-- Creates a new link.
--
-- Args:
-- * self: Layers object.
-- * lowEntry: Entry with the lowest layerId to link.
-- * highEntry: Entry with the greatest layerId to link.
-- * isForward: True if the link goes from lowEntry to highEntry, false otherwise.
--
function Impl.newLink2(self,highEntry,lowEntry,isForward)
    Impl.newLink(self, lowEntry, highEntry, isForward)
end

-- Creates a new Layers object, with no vertices or edges.
--
-- Args:
-- * object: Table to turn into a Layers object (must have a channelIndexFactory field).
--
-- Returns: The new Layers object.
--
function Layers.new(object)
    assert(object.channelIndexFactory, "Layers.new(): missing channelIndexFactory field.")
    object.entries = Array.new()
    object.links = ErrorOnInvalidRead.new{
        forward = ErrorOnInvalidRead.new(),
        backward = ErrorOnInvalidRead.new(),
    }
    object.linkNodes = ErrorOnInvalidRead.new()
    object.reverse = ErrorOnInvalidRead.new{
        edge = ErrorOnInvalidRead.new(),
        linkNode = ErrorOnInvalidRead.new(),
        vertex = ErrorOnInvalidRead.new(),
    }
    setmetatable(object, Impl.Metatable)
    return object
end

return Layers
