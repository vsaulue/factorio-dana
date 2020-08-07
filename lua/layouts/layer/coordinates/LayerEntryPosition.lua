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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local TreeLinkNode = require("lua/layouts/TreeLinkNode")

local cLogger = ClassLogger.new{className = "LayerEntryPosition"}

local buildNodes
local computeSlotsX
local computeSlotsY
local Metatable
local nodesFieldName

-- Class holding placement data of a specific entry.
--
-- The X coordinate of slots are directly stored in their associated link node.
--
-- RO fields:
-- * entry: LayerEntry object whose position is held.
-- * output: placement data of this entry, returned in the LayoutCoordinates object.
-- * lowNodes[linkIndex]: Tree node of the given link index for low slots.
-- * highNodes[linkIndex]: Tree node of the given link index for high slots.
--
-- Methods:
-- * getNode: Gets the tree node associated to the given slot.
-- * initX: Initializes the X coordinates of this object.
-- * translateX: Moves this object on the X axis.
--
local LayerEntryPosition = ErrorOnInvalidRead.new{
    -- Turns a table into a LayerEntryPosition object.
    --
    -- Args:
    -- * object: The table to turn into a LayerEntryPosition object (required fields: entry, output).
    --
    -- Returns: object, turned into a LayerEntryPosition object.
    --
    new = function(object)
        local entry = cLogger:assertField(object, "entry")
        cLogger:assertField(object, "output")

        object.lowNodes = buildNodes(entry.lowSlots, entry)
        if entry.type == "linkNode" then
            object.highNodes = object.lowNodes
        else
            object.highNodes = buildNodes(entry.highSlots, entry)
        end

        setmetatable(object, Metatable)
        return object
    end,
}

-- Metatable of the LayerEntryPosition class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Gets the tree node associated to the given slot.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * linkIndex: LinkIndex of the slot.
        -- * isInbound: true for an inbound slot, false otherwise.
        --
        -- Returns: The tree object associated to the given slot.
        --
        getNode = function(self, linkIndex, isInbound)
            return self[nodesFieldName[isInbound]][linkIndex]
        end,

        -- Sets the X coordinates of the node (margin excluded) and the attached links.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * xMin: New xMin value.
        --
        setXMin = function(self, xMin)
            local output = self.output
            output:setXMin(xMin)
            local xLength = output:getXLength(false)

            local entry = self.entry
            computeSlotsX(entry.lowSlots, self.lowNodes, xMin, xLength)
            computeSlotsX(entry.highSlots, self.highNodes, xMin, xLength)
        end,

        -- Sets the Y coordinates of the node (margin excluded) and the attached links.
        --
        -- Args:
        -- * self: LayerEntryPosition object.
        -- * yMin: New yMin value.
        --
        setYMin = function(self, yMin)
            local output = self.output
            output:setYMin(yMin)
            computeSlotsY(self.lowNodes, output, true)
            computeSlotsY(self.highNodes, output, false)
        end,
    },
}

-- Builds a map of Tree nodes corresponding to a ReversibleArray of LayerLinkIndex.
--
-- Args:
-- * slots: ReversibleArray of LayerLinkIndex.
-- * entry: LayerEntry object owning the slots.
--
-- Returns: A map of Tree objects, indexed by channel indexes.
--
buildNodes = function(slots, entry)
    local result = ErrorOnInvalidRead.new()
    local type = entry.type
    for i=1,slots.count do
        local linkIndex = slots[i]
        local linkNode = TreeLinkNode.new()
        if type == "node" then
            if entry.index == linkIndex.rootNodeIndex then
                linkNode.linkIndex = linkIndex
            else
                linkNode.edgeIndex = entry.index
            end
        else
            linkNode.infoHint = true
        end
        result[linkIndex] = linkNode
    end
    return result
end

-- Fills x field of a set of link nodes.
--
-- Args:
-- * slots: ReversibleArray of slots (ex: LayerEntry.lowSlots).
-- * nodes: Map of link nodes, indexed by channel indexes.
-- * xMin: New xMin value of the entry.
-- * xLength: Length of the entry.
--
computeSlotsX = function(slots, nodes, xMin, xLength)
    local count = slots.count
    for rank=1,count do
        local linkIndex = slots[rank]
        local node = nodes[linkIndex]
        node.x = xMin + xLength * (rank - 0.5) / count
    end
end

-- Sets the y field of a set of link nodes.
--
-- Args:
-- * linkNodes: Map of link nodes, indexed by channel indexes.
-- * node: RectangleNode on which the links must be attached.
-- * isFromLowY: True if links are attached to the low-Y side. False for the high-Y side.
--
computeSlotsY = function(linkNodes, node, isFromLowY)
    for _,linkNode in pairs(linkNodes) do
        linkNode.y = node:yProject(linkNode.x, isFromLowY)
    end
end

-- Map giving the field name for slot nodes.
nodesFieldName = ErrorOnInvalidRead.new{
    [true] = "lowNodes",
    [false] = "highNodes",
}

return LayerEntryPosition
