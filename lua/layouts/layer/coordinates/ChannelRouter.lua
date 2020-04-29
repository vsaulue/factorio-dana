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

local AntisymBivarMap = require("lua/containers/AntisymBivarMap")
local Array = require("lua/containers/Array")
local ArrayBinarySearch = require("lua/containers/utils/ArrayBinarySearch")
local ChannelBranch = require("lua/layouts/layer/coordinates/ChannelBranch")
local DirectedGraph = require("lua/graph/DirectedGraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Iterator = require("lua/containers/utils/Iterator")
local MinimumFAS = require("lua/graph/algorithms/MinimumFAS")
local StackAvlTree = require("lua/containers/StackAvlTree")
local TopologicalOrderGenerator = require("lua/graph/algorithms/TopologicalOrderGenerator")
local Tree = require("lua/containers/Tree")

-- Class handling the coordinate generation of a ChannelLayer.
--
-- The terminology is taken from the electronic field:
-- * branch: a line along the Y-axis linking an entry's slot to the main channel line (=trunk).
-- * trunk: a line along the X-axis linking all branches having the same channel index together.
-- * track: a set of trunks that have the same Y-coordinate.
--
-- As for the electronic variant, the goal of this router is to:
-- * computes the branches & trunks
-- * assign each trunk to a track (= a Y coordinate). Multiple trunks can share a track, as long as they don't overlap.
--
-- However the algorithms don't have much in common. Routers for electronics are tuned for physical & economic
-- constraints, while this router aims at ploting a "nice looking" solution.
--
-- RO Fields:
-- * channelLayer: ChannelLayer object being mapped to coordinates.
-- * entryPositions[entry]: Map giving the LayerEntryPosition object of a LayerEntry.
-- * linkWidth: Width of links, including margins.
-- * roots[channelIndex]: Map of generated Tree for each channel, useable for tree links.
-- * tracks[trackId][trunkRank]: 2-dim Array of ChannelIndex.
-- * trunks[channelIndex]: Map of trunks for each channel (trunk = Array of ChannelBranches).
--
local ChannelRouter = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local buildTracks
local buildOrder
local buildTrees
local generateTrunks
local makeBranches

-- Metatable of the ChannelRouter class.
local Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Assigns an Y coordinate to trunk nodes.
        --
        -- Args:
        -- * self: ChannelRouter object.
        -- * yMin: Minimum Y coordinate of the channel layer.
        --
        -- Returns: The maximum Y coordinate of the channel layer.
        --
        setY = function(self, yMin)
            local linkWidth = self.linkWidth
            local tracks = self.tracks
            local trunks = self.trunks
            local y = yMin + linkWidth / 2
            for trackId=1,tracks.count do
                local track = tracks[trackId]
                for trunkRank=1,track.count do
                    local channelIndex = track[trunkRank]
                    local trunk = trunks[channelIndex]
                    for branchId=1,trunk.count do
                        local branch = trunk[branchId]
                        branch.trunkNode.y = y
                    end
                end
                y = y + linkWidth
            end
            return y - linkWidth / 2
        end
    },
}

-- Generates an array of tracks, filled with all the trunks of this layer.
--
-- Args:
-- * self: ChannelRouter object.
-- *
--
-- Returns: A 2-dim Array of channel indexes, representing the tracks.
--
buildTracks = function(self)
    local result = Array.new()
    local avlTree = StackAvlTree.new()
    local trunks = self.trunks
    local orderGenerator = TopologicalOrderGenerator.new{
        candidateCallback = function(channelIndex)
            local trunk = trunks[channelIndex]
            avlTree:push(trunk[1].x, channelIndex)
        end,
        graph = buildOrder(self),
    }

    while avlTree.count > 0 do
        local newTrack = Array.new()
        local currentX,channelIndex = avlTree:popGreater(-math.huge, false)
        repeat
            orderGenerator:select(channelIndex)
            newTrack:pushBack(channelIndex)
            local trunk = trunks[channelIndex]
            local nextX = trunk[trunk.count].x + self.linkWidth
            currentX,channelIndex = avlTree:popGreater(nextX, false)
        until currentX == nil
        result:pushBack(newTrack)
    end

    return result
end

-- Fills the roots field, and links tree nodes together to form the trees.
--
-- Args:
-- * self: ChannelRouter object.
--
buildTrees = function(self)
    for channelIndex,trunk in pairs(self.trunks) do
        local root = nil
        for i=1,trunk.count do
            local branch = trunk[i]
            local trunkNode = branch.trunkNode
            if root then
                trunkNode:addChild(root)
            end
            trunkNode:addChild(branch.entryNode)
            root = trunkNode
        end
        assert(root)
        self.roots[channelIndex] = root
    end
end

-- Parses the ChannelLayer's high/low entries, and generates trunks.
--
-- Args:
-- * self: ChannelRouter object.
--
generateTrunks = function(self)
    local channelLayer = self.channelLayer
    for channelIndex,lowEntries in pairs(channelLayer.lowEntries) do
        local highEntries = channelLayer.highEntries[channelIndex]
        local trunk = Array.new()
        self.trunks[channelIndex] = trunk
        local lowBranches = makeBranches(self, lowEntries, channelIndex, true)
        local highBranches = makeBranches(self, highEntries, channelIndex, false)

        local itLow = Iterator.new(lowBranches)
        itLow:next()
        local itHigh = Iterator.new(highBranches)
        itHigh:next()
        while itLow.value and itHigh.value do
            if itLow.value.x < itHigh.value.x then
                trunk:pushBackIteratorOnce(itLow)
            else
                trunk:pushBackIteratorOnce(itHigh)
            end
        end
        trunk:pushBackIteratorAll(itLow)
        trunk:pushBackIteratorAll(itHigh)
    end
end

-- Generates an array of ChannelBranch from an array of LayerEntry.
--
-- Args:
-- * self: ChannelRouter object.
-- * entryArray: Input Array of LayerEntry.
-- * channelIndex: Channel index of the generated branches.
-- * isLow: isLow value of the generated branches.
--
-- Returns: A new array of ChannelBranch, corresponding to the entries in entryArray.
--
makeBranches = function(self, entryArray, channelIndex, isLow)
    local entryPositions = self.entryPositions
    local count = entryArray.count
    local result = Array.new()
    for i=1,count do
        local entry = entryArray[i]
        local entryPos = entryPositions[entry]
        local newBranch = ChannelBranch.new{
            channelIndex = channelIndex,
            entryPosition = entryPos,
            isLow = isLow,
        }
        result[i] = newBranch
    end
    result.count = count
    return result
end

-- Builds the partial order that will be used to assign trunks to tracks.
--
-- Current algorithm attempts to minimize the number of crossings between branches <-> trunks.
--
-- Args:
-- * self: ChannelRouter object.
--
-- Returns: The order in the form of an acyclic DirectedGraph (vertex indices = channel indices)
--
buildOrder = function(self)
    local graph = DirectedGraph.new()
    local crossings  = AntisymBivarMap.new()
    local allBranches = Array.new()
    local branchX = ErrorOnInvalidRead.new()
    for channelIndex,trunk in pairs(self.trunks) do
        graph:addVertexIndex(channelIndex)
        crossings:newIndex(channelIndex)
        for i=1,trunk.count do
            local branch = trunk[i]
            allBranches:pushBack(branch)
            branchX[branch] = branch.x
        end
    end
    allBranches:sort(branchX)
    branchX = Array.new()
    for i=1,allBranches.count do
        branchX[i] = allBranches[i].x
    end
    branchX.count = allBranches.count
    for trunkIndex,trunk in pairs(self.trunks) do
        local lowId,highId = ArrayBinarySearch.findIndexesInRange(branchX, trunk[1].x, trunk[trunk.count].x, false, false)
        for i=lowId,highId do
            local branch = allBranches[i]
            local branchIndex = branch.channelIndex
            if branchIndex ~= trunkIndex then
                local delta = 1
                if branch.isLow then
                    delta = -1
                end
                crossings:addToCoefficient(trunkIndex, branchIndex, delta)
            end
        end
    end

    local relationOrder = crossings.order
    for i=1,relationOrder.count do
        local cIndex1 = relationOrder[i]
        for cIndex2,weight in pairs(crossings[cIndex1]) do
            if weight > 0 then
                graph:addEdge(cIndex1, cIndex2, weight)
            else
                graph:addEdge(cIndex2, cIndex1, -weight)
            end
        end
    end

    MinimumFAS.run(graph):removeFeedbackEdges()
    return graph
end

-- Creates a new ChannelRouter object.
--
-- Args:
-- * object: Table to turn into a ChannelRouter object (mandatory fields: channelLayer, entryPositions, linkWidth, yMin).
--
function ChannelRouter.new(object)
    assert(object.channelLayer, "ChannelRouter: missing mandatory 'channelLayer' field.")
    assert(object.entryPositions, "ChannelRouter: missing mandatory 'entryPositions' field.")
    assert(object.linkWidth, "ChannelRouter: missing mandatory 'linkWidth' field.")

    setmetatable(object, Metatable)
    object.trunks = ErrorOnInvalidRead.new()
    object.roots = ErrorOnInvalidRead.new()

    generateTrunks(object)
    object.tracks = buildTracks(object)
    buildTrees(object)

    return object
end

return ChannelRouter
