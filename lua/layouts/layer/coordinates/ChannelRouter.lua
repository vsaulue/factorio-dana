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

local Array = require("lua/containers/Array")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local Iterator = require("lua/containers/utils/Iterator")
local Tree = require("lua/containers/Tree")

-- Class handling the coordinate generation of a ChannelLayer.
--
-- Subtype: ChannelBranch
-- * channelIndex: Channel index of the linked trunk and slot.
-- * entryNode: Tree node attached to the entry.
-- * entryPosition: LayerEntryPosition object.
-- * isLow: True if the entry is in the lower entry layer, false otherwise.
-- * trunkNode: Tree node attached to the trunk.
--
-- RO Fields:
-- * yMin: maximum "y" coordinate of objects in the last layer.
-- * channelLayer: ChannelLayer object being mapped to coordinates.
-- * entryPositions[entry]: Map giving the LayerEntryPosition object of a LayerEntry.
-- * linkWidth: Width of links, including margins.
-- * roots[channelIndex]: Map of generated Tree for each channel, useable for tree links.
-- * trunks[channelIndex]: Map of trunks for each channel (trunk = Array of ChannelBranches).
-- * yLength: "y" length of the generated layout for this channel layer.
--
local ChannelRouter = ErrorOnInvalidRead.new{
    new = nil,
}

-- Implementation stuff (private scope).
local buildTrees
local computeY
local generateTrunks
local makeBranches

-- Map giving the field name for slot nodes in LayerEntryPosition.
local nodesFieldName = ErrorOnInvalidRead.new{
    [false] = "inboundNodes",
    [true] = "outboundNodes",
}

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

-- Assigns an Y coordinate to trunk nodes.
--
-- Args:
-- * self: ChannelRouter object.
--
computeY = function(self)
    local linkWidth = self.linkWidth
    local order = self.channelLayer.order
    local y = self.yMin + linkWidth / 2
    for i=1,order.count do
        local channelIndex = order[i]
        local trunk = self.trunks[channelIndex]
        for j=1,trunk.count do
            local branch = trunk[j]
            branch.trunkNode.y = y
        end
        y = y + linkWidth
    end
    self.yLength = y - linkWidth / 2 - self.yMin
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
        local x = entryPos:getSlotAbsoluteX(channelIndex, not isLow)
        local entryNode = Tree.new{
            x = x,
        }
        result[i] = ErrorOnInvalidRead.new{
            channelIndex = channelIndex,
            entryNode = entryNode,
            entryPosition = entryPos,
            isLow = isLow,
            trunkNode = Tree.new{
                x = x,
            },
            x = x,
        }
        entryPos[nodesFieldName[isLow]][channelIndex] = entryNode
    end
    result.count = count
    return result
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
    assert(object.yMin, "ChannelRouter: missing mandatory 'yMin' field.")

    ErrorOnInvalidRead.setmetatable(object)
    object.trunks = ErrorOnInvalidRead.new()
    object.roots = ErrorOnInvalidRead.new()

    generateTrunks(object)
    computeY(object)
    buildTrees(object)

    return object
end

return ChannelRouter
