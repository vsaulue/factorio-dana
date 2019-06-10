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

-- Class holding layers for a layer graph representation.
--
-- Each node entry (node in the layer graph) is a table with the following fields:
-- * type: must be either "edge", "link", or "vertex".
-- * index: an identifier.
--
-- For an entry, {type,index} acts as a primary key: duplicates are forbidden.
--
-- RO fields:
-- * entries[layerId,rankInLayer]: 2-dim array representing the layers.
-- * maxLayerId: index of the latest layer.
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
        },
    },

    link = nil, -- implemented later

    -- Adds a new entry to this layout.
    --
    -- Args:
    -- * self: Layers object.
    -- * layerIndex: Index of the layer in which the entry will be inserted.
    -- * entry: the new entry.
    --
    newEntry = function(self,layerIndex,entry)
        assert(not self.reverse[entry.type][entry.index], "Layers: duplicate primary key.")
        entry.uplinks = {}
        if self.maxLayerId < layerIndex then
            for i=self.maxLayerId+1,layerIndex do
                self.entries[i] = {}
            end
            self.maxLayerId = layerIndex
        end
        local rank = 1 + #self.entries[layerIndex]
        self.entries[layerIndex][rank] = entry
        self.reverse[entry.type][entry.index] = {layerIndex, rank}
    end,
}

function Impl.Metatable.__index.newEdge(self,layerIndex,edge)
    local edgeEntry = {
        type = "edge",
        index = edge.index,
    }
    Impl.newEntry(self,layerIndex, edgeEntry)

    for _,vertexIndex in pairs(edge.inbound) do
        local vertexEntry = self:getEntry("vertex",vertexIndex)
        Impl.link(self,edgeEntry, vertexEntry)
    end

    for _,vertexIndex in pairs(edge.outbound) do
        local vertexEntry = self:getEntry("vertex",vertexIndex)
        Impl.link(self,edgeEntry, vertexEntry)
    end
end

function Impl.Metatable.__index.newVertex(self,layerIndex,vertexIndex)
    Impl.newEntry(self,layerIndex,{
        type = "vertex",
        index = vertexIndex,
        linkNodes = {},
    })
end

-- Creates a link entry between a vertex and an edge.
--
-- Args:
-- * self: Layers object.
-- * edgeEntry: Entry of the edge to link.
-- * vertexEntry: Entry of the vertex to link.
--
function Impl.link(self,edgeEntry,vertexEntry)
    local edgePos = self.reverse[edgeEntry.type][edgeEntry.index]
    local vertexPos = self.reverse[vertexEntry.type][vertexEntry.index]

    -- Default values: edgePos[1] <= vertexPos[1]
    local minLayerId = vertexPos[1]
    local minEntry = vertexEntry
    local maxLayerId = edgePos[1]
    local maxEntry = edgeEntry
    if vertexPos[1] > edgePos[1] then
        minLayerId = edgePos[1]
        minEntry = edgeEntry
        maxLayerId = vertexPos[1]
        maxEntry = vertexEntry
    end

    local i = maxLayerId - 1
    local previousEntry = maxEntry
    local connected = false
    while not connected do
        if i > minLayerId then
            if vertexEntry.linkNodes[i] then
                table.insert(previousEntry.uplinks, vertexEntry.linkNodes[i])
                connected = true
            else
                local entry = {
                    type = "link",
                    index = {},
                }
                Impl.newEntry(self, i, entry)
                vertexEntry.linkNodes[i] = entry
                i = i - 1
                table.insert(previousEntry.uplinks, entry)
                previousEntry = entry
            end
        else
            table.insert(previousEntry.uplinks, minEntry)
            connected = true
        end
    end
end

-- Creates a new Layers object, with no vertices or edges.
--
-- Returns: The new Layers object.
--
function Layers.new()
    local result = {
        entries = {},
        maxLayerId = 0,
        reverse = {
            edge = {},
            link = {},
            vertex = {},
        },
    }
    setmetatable(result, Impl.Metatable)
    return result
end

return Layers
