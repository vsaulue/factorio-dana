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
local LayerEntry = require("lua/layouts/layer/LayerEntry")

local Metatable

-- Class holding the vertex & edge relative positions in a layer layout.
--
-- For an entry, {type,index} acts as a primary key: duplicates are forbidden.
--
-- RO fields:
-- * entries[layerId,rankInLayer]: 2-dim Array of LayerEntry, representing the layers.
-- * reverse[type,index]: 2-dim array giving coordinates from keys (reverse of entries).
--
-- Methods: see Metatable.__index.
--
local Layers = ErrorOnInvalidRead.new{
    -- Creates a new Layers object, with no vertices or edges.
    --
    -- Returns: The new Layers object.
    --
    new = function()
        local result = {
            entries = Array.new(),
            reverse = ErrorOnInvalidRead.new{
                linkNode = ErrorOnInvalidRead.new(),
                node = ErrorOnInvalidRead.new(),
            },
        }
        setmetatable(result, Metatable)
        return result
    end,
}

-- Metatable of the Layers class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Generates the channel layers for this layer layout.
        --
        -- N+1 channel layers are generated (N being the number of entry layers). The first channel
        -- layer returned by this function is placed before the first entry layer. The last channel
        -- layer of the returned array is placed after the last entry layer.
        --
        -- Args:
        -- * self: Layers object.
        --
        -- Returns: An array containing the generated channel layers.
        --
        generateChannelLayers = function(self)
            local entries = self.entries
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
                    local lowSlots = entry.lowSlots
                    for i=1,lowSlots.count do
                        lowChannelLayer:appendHighEntry(lowSlots[i], entry)
                    end
                    local highSlots = entry.highSlots
                    for i=1,highSlots.count do
                        highChannelLayer:appendLowEntry(highSlots[i], entry)
                    end
                end
            end

            return result
        end,

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

        -- Gets the position of an entry.
        --
        -- Args:
        -- * self: Layers object.
        -- * entry: Entry to lookup.
        --
        -- Returns: The position of the given entry ([1] = layerId, [2] = rank).
        --
        getPos = function(self, entry)
            return self.reverse[entry.type][entry.index]
        end,

        -- Creates and add a new entry to this layout.
        --
        -- Args:
        -- * self: Layers object.
        -- * layerIndex: Index of the layer in which the entry will be inserted.
        -- * entry: Constructor argument for the new LayerEntry.
        --
        newEntry = function(self, layerIndex, entry)
            local newEntry = LayerEntry.new(entry)
            assert(not rawget(self.reverse[newEntry.type], newEntry.index), "Layers: duplicate primary key.")
            if self.entries.count < layerIndex then
                for i=self.entries.count+1,layerIndex do
                    self.entries[i] = Array.new()
                end
                self.entries.count = layerIndex
            end
            local layer = self.entries[layerIndex]
            layer:pushBack(newEntry)
            local pos = {layerIndex, layer.count}
            self.reverse[newEntry.type][newEntry.index] = pos
        end,

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
}

return Layers
