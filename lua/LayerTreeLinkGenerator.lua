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

local ErrorOnInvalidRead = require("lua/ErrorOnInvalidRead")
local Logger = require("lua/Logger")
local Tree = require("lua/Tree")

-- Helper library to compute the tree links of a LayerLayout object.
--
local LayerTreeLinkGenerator = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = ErrorOnInvalidRead.new{
    getXSlotCoordinate = nil, -- implemented later

    getSlotCoordinates = nil, -- implemented later

    -- Parser data to generate trees from high to low layer indexes.
    HighToLowData = ErrorOnInvalidRead.new{
        -- Indicates if we're parsing layers from lower to higher index.
        isLowToHigh = false,

        -- Name of the table containing the links to parse (in Layers.links).
        linksName = "backward",

        -- Name of the slots field in the VertexEntry to parse.
        vertexSlotName = "inboundSlots",

        -- Name of the Y coordinate field to use for the vertex slot.
        yVertexCoordName = "yMin",
    },

    -- Parser data to generate trees from low to high layer indexes.
    LowToHighData = ErrorOnInvalidRead.new{
        isLowToHigh = true,
        linksName = "forward",
        vertexSlotName = "outboundSlots",
        yVertexCoordName = "yMax",
    },

    makeTree = nil, -- implemented later

    runOneDirection = nil, -- implemented later
}

-- Get the X coordinate of a slot by its rank.
--
-- Args:
-- * entryPosition: Position data of the entry.
-- * rank: Rank of the slot.
-- * slotCount: Total number of slots.
--
-- Returns: The X coordinate of the slot.
--
function Impl.getXSlotCoordinate(entryPosition, rank, slotCount)
    local xMin = entryPosition.xMin
    return xMin + (entryPosition.xMax - xMin) * (rank - 0.5) / slotCount
end

-- Get the coordinates of a slot by its channel index.
--
-- Args:
-- * coordinateGenerator: LayerCoordinateGenerator object of the layout to generate.
-- * entry: Entry containing the desired slot.
-- * channelIndex: ChannelIndex of the desired slot.
-- * isInbound: True to parse inbound slots. False for outbound slots.
--
-- Returns:
-- * X coordinate of the slot.
-- * Y coordinate of the slot.
--
function Impl.getSlotCoordinates(coordinateGenerator, entry, channelIndex, isInbound)
    local entryPosition = coordinateGenerator.entryPositions[entry.type][entry.index]
    local slots = entry.outboundSlots
    local y = entryPosition.yMax
    if isInbound then
        slots = entry.inboundSlots
        y = entryPosition.yMin
    end
    local x = Impl.getXSlotCoordinate(entryPosition, slots[channelIndex], slots.count)
    return x,y
end

-- Creates a LinkTree recursively.
--
-- #TODO: non recursive implementation.
--
-- Args:
-- * coordinateGenerator: LayerCoordinateGenerator object of the layout to generate.
-- * parentEntry: Entry associated of the root of the generated tree.
-- * link: Link between `parentEntry` and the entry whose tree must be generated.
-- * parserData: Object indicating how to parse the Layers object.
--
-- Returns: A Tree object, for the entry obtained by following `link` from `parentEntry`.
--
function Impl.makeTree(coordinateGenerator, parentEntry, link, parserData)
    local childEntry = link:getOtherEntry(parentEntry)
    local channelIndex = link.channelIndex
    local x,y = Impl.getSlotCoordinates(coordinateGenerator, childEntry, channelIndex, parserData.isLowToHigh)
    local result = Tree.new{
        x = x,
        y = y,
    }
    local type = childEntry.type
    if type == "linkNode" then
        local links = coordinateGenerator.layout.layers.links[parserData.linksName][childEntry]
        local makeTree = Impl.makeTree
        for nextLink in pairs(links) do
            local subTree = makeTree(coordinateGenerator, childEntry, nextLink, parserData)
            result.children[subTree] = true
        end
    else
        if type ~= "edge" then
            Logger.error("LayerLayout: link connecting multiple vertices together.")
        end
        result.type = type
        result.index = childEntry.index
    end
    return result
end

-- Generates all trees from either the inboundSlots or the outboundSlots.
--
-- Generated trees are added to coordinateGenerator.result.links.
--
-- Args:
-- * coordinateGenerator: LayerCoordinateGenerator object of the layout to generate.
-- * entry: Vertex entry from which trees are generated.
-- * parserData: Object indicating how to parse the Layers object.
--
function Impl.runOneDirection(coordinateGenerator, entry, parserData)
    local entryPosition = coordinateGenerator.entryPositions[entry.type][entry.index]
    local trees = ErrorOnInvalidRead.new()
    local slots = entry[parserData.vertexSlotName]
    local y = entryPosition[parserData.yVertexCoordName]
    local slotsCount = slots.count
    local getX = Impl.getXSlotCoordinate
    for i=1,slotsCount do
        local channelIndex = slots[i]
        local x = getX(entryPosition, slots[channelIndex], slotsCount)
        local category = "forward"
        if not channelIndex.isForward then
            category = "backward"
        end
        local newLinkTree = ErrorOnInvalidRead.new{
            category = category,
            tree = Tree.new{
                x = x,
                y = y,
            },
        }
        coordinateGenerator.result.links[newLinkTree] = true
        trees[channelIndex] = newLinkTree.tree
    end
    local links = coordinateGenerator.layout.layers.links[parserData.linksName][entry]
    local makeTree = Impl.makeTree
    for link in pairs(links) do
        local newTree = makeTree(coordinateGenerator, entry, link, parserData)
        trees[link.channelIndex].children[newTree] = true
    end
end

-- Generates the tree links object of a specified vertex entry.
--
-- Generated trees are added to coordinateGenerator.result.links.
--
-- Args:
-- * coordinateGenerator: LayerCoordinateGenerator object of the layout to generate.
-- * vertexEntry: LayerEntry object of a vertex. All trees starting from this entry will be generated.
--
function LayerTreeLinkGenerator.run(coordinateGenerator, vertexEntry)
    Impl.runOneDirection(coordinateGenerator, vertexEntry, Impl.HighToLowData)
    Impl.runOneDirection(coordinateGenerator, vertexEntry, Impl.LowToHighData)
end

return LayerTreeLinkGenerator
