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
local Couplings = require("lua/layouts/layer/Couplings")
local CouplingScoreOptimizer = require("lua/layouts/layer/CouplingScoreOptimizer")
local EquivalenceClasses = require("lua/layouts/layer/EquivalenceClasses")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local OrderedSet = require("lua/containers/OrderedSet")

-- Helper class for sorting entries in their layers.
--
-- This is a global algorithm, parsing the full layer graph, and using a heuristic to give an initial
-- "good enough" ordering of layers. Local heuristics can refine the work after that.
--
-- Fields:
-- * channelLayers: ChannelLayers of the layout to sort.
-- * layersSortingData[layerId]: Map of LayerSortingData (internal type), indexed by layer index.
-- * layers: Layers object, whose layers are to be sorted.
--
local LayersInitialSorter = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Implementation stuff (private scope).
local computeCouplings
local computePosition
local createCouplings
local parseInput
local sortByHighestCouplingCoefficient
local sortLayers

-- Layer sorting data.
--
-- Fields:
-- * lowChannels[channelIndex]: Map giving the parent entries of a low channel.
-- * equivalenceClasses: EquivalenceClasses object, holding entries directly placeable from lowChannels, or roots.
-- * secondPass[entry]: Map of entry -> vertex entry. The vertex entry must be in firstPass or roots.
-- * couplings: Couplings object, holding coefficients between all entries of this layer.
--
local LayerSortingData = ErrorOnInvalidRead.new{
    -- Creates a new LayerSortingData object.
    --
    -- Args:
    -- * layer: Array of LayerEntry associated to this object.
    --
    -- Returns: The new LayerSortingData object.
    --
    new = function(layer)
        local couplings = Couplings.new()
        local result = ErrorOnInvalidRead.new{
            lowChannels = ErrorOnInvalidRead.new(),
            equivalenceClasses = EquivalenceClasses.new(),
            secondPass = ErrorOnInvalidRead.new(),
            couplings = couplings,
        }
        for x=1,layer.count do
            couplings:newElement(layer[x])
        end
        return result
    end,
}

-- Computes the coupling coefficients between entries in a given layer.
--
-- Args:
-- * newCouplings: The Couplings object to fill.
-- * higherCouplings: The Couplings object of the higher layer.
-- * children[entry]: Map indexed by entries in higherCouplings.order. Gives an Array of linked elements in newCouplings.
--
computeCouplings = function(newCouplings, higherCouplings, children)
    local order = higherCouplings.order
    for i=1,order.count do
        local elemI = order[i]
        local couplingsI = higherCouplings[elemI]
        local childrenI = children[elemI]
        local countI = childrenI.count
        -- Recursive couplings: couplings between higherCouplings' elements induce coupling between their children.
        for elemJ,coef in pairs(couplingsI) do
            local childrenJ = children[elemJ]
            local countJ = childrenJ.count
            local delta = coef / (countI * countJ)
            for a=1,countI do
                local elemA = childrenI[a]
                for b=1,countJ do
                    local elemB = childrenJ[b]
                    if elemA ~= elemB then
                        newCouplings:addToCoupling(elemA, elemB, delta)
                    end
                end
            end
        end
        -- New couplings: a single element from higherCouplings induces coupling between all its children.
        local delta = 1 / (countI * countI)
        for a=1,countI do
            local elemA = childrenI[a]
            for b=a+1,countI do
                local elemB = childrenI[b]
                newCouplings:addToCoupling(elemA, elemB, delta)
            end
        end
    end
end

-- Computes the position of an element.
--
-- Args:
-- * positions[element]: Map giving the position of parent element by their index.
-- * parents: Array containing the parents of the element.
--
-- Returns: The position of the element associated with `parents`.
--
computePosition = function(positions, parents)
    local count = parents.count
    local newPos = 0
    for i=1,count do
        local parent = parents[i]
        newPos = newPos + positions[parent]
    end
    return newPos / count
end

-- Computes coupling scores between each roots.
--
-- Args:
-- * self: LayersInitialSorter object.
--
-- Returns: a 2-dim map, giving the coupling between root entries.
--
createCouplings = function(self)
    local channelLayers = self.channelLayers
    local entries = self.layers.entries
    local layersCount = entries.count
    local prevCouplings = nil
    for layerId=layersCount,1,-1 do
        local layerData = self.layersSortingData[layerId]
        local highChannelLayer = channelLayers[layerId+1]

        local channelCouplings = Couplings.new()
        for channelIndex in pairs(highChannelLayer.lowEntries) do
            channelCouplings:newElement(channelIndex)
        end
        if prevCouplings then
            local children = ErrorOnInvalidRead.new()
            local order = prevCouplings.order
            for i=1,order.count do
                local entry = order[i]
                children[entry] = entry.inboundSlots
            end
            computeCouplings(channelCouplings, prevCouplings, children)
        end

        computeCouplings(layerData.couplings, channelCouplings, highChannelLayer.lowEntries)

        prevCouplings = layerData.couplings
    end
end

-- Parses the input Layers object into useful intermediate data.
--
-- Args:
-- * self: LayersInitialSorter object.
--
parseInput = function(self)
    local channelLayers = self.channelLayers
    local entries = self.layers.entries
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local layerData = LayerSortingData.new(layer)
        local entryParents = ErrorOnInvalidRead.new()
        self.layersSortingData[layerId] = layerData
        for rank=1,layer.count do
            entryParents[layer[rank]] = Array.new()
        end

        -- First pass: process channels with lower & higher entries.
        local lowChannelLayer = channelLayers[layerId]
        local pureLowChannels = ErrorOnInvalidRead.new()
        for channelIndex,lowEntries in pairs(lowChannelLayer.lowEntries) do
            local highEntries = lowChannelLayer.highEntries[channelIndex]
            if lowEntries.count == 0 then
                pureLowChannels[channelIndex] = highEntries
            else
                layerData.lowChannels[channelIndex] = lowEntries
                for i=1,highEntries.count do
                    entryParents[highEntries[i]]:pushBack(channelIndex)
                end
            end
        end

        -- Second pass: process channels which have only higher entries.
        -- Right now, horizontal high channels are only backward links looping back to a vertex entry.
        -- They should only be attached to linkNodes, and those will be placed next to the vertex entry
        -- in the secondPass.
        for channelIndex,highEntries in pairs(pureLowChannels) do
            local vertexEntry = nil
            for i=1,highEntries.count do
                local entry = highEntries[i]
                if entry.type == "vertex" then
                    assert(not vertexEntry, "LayersInitialSorter: channel has multiple vertex entries.")
                    vertexEntry = entry
                end
            end
            if vertexEntry then
                for i=1,highEntries.count do
                    local entry = highEntries[i]
                    if entry ~= vertexEntry then
                        layerData.secondPass[entry] = vertexEntry
                    end
                end
            end
        end

        -- Third pass: assign any unprocessed entry to either roots or firstPass sets.
        for rank=1,layer.count do
            local entry = layer[rank]
            if not rawget(layerData.secondPass, entry) then
                local parents = entryParents[entry]
                layerData.equivalenceClasses:addToClass(parents, entry)
            end
        end
    end
end

-- Sorts an array of elements, by their highest coefficient in a Couplings object.
--
-- Args:
-- * elements: Array of elements to sort.
-- * couplings: Couplings object holding coefficients for the given array of elements.
--
sortByHighestCouplingCoefficient = function(elements, couplings)
    local rootGreatestCouplings = {}
    local max = math.max
    local count = elements.count
    for i=1,count do
        local elemI = elements[i]
        for j=i+1,count do
            local elemJ = elements[j]
            local coupling = couplings:getCoupling(elemI, elemJ)
            rootGreatestCouplings[elemI] = max(coupling, rootGreatestCouplings[elemI] or 0)
            rootGreatestCouplings[elemJ] = max(coupling, rootGreatestCouplings[elemJ] or 0)
        end
    end
    elements:sort(rootGreatestCouplings)
end

-- Run the sorting algorithm on each layers.
--
-- Sorting is done layer by layer, following this a multi-step pipeline:
-- * 1) Greedily place firstPass entries, at the barycenter of their inbound channel indexes.
-- * 2) Insert roots, by trying to minimize couplings score of the layer.
-- * 3) Places secondPass entries, as barycenter of their parents.
--
-- Between each step of the pipeline, the result is consolidated in an array. The next step
-- uses the rank of entries from the previous step as positions.
--
-- Args:
-- * self: LayersInitialSorter object.
--
sortLayers = function(self)
    local entries = self.layers.entries
    for layerId=1,entries.count do
        local layer = entries[layerId]
        local layerData = self.layersSortingData[layerId]
        local newOrder = Array.new()
        -- 1) lowChannels & firstPass
        if layerId > 1 then
            local prevLayer = entries[layerId-1]
            local parentPositions = ErrorOnInvalidRead.new()
            local positions = ErrorOnInvalidRead.new()
            for rank=1,prevLayer.count do
                local entry = prevLayer[rank]
                parentPositions[entry] = rank
            end
            for channelIndex,lowEntries in pairs(layerData.lowChannels) do
                parentPositions[channelIndex] = computePosition(parentPositions, lowEntries)
            end
            for parents,classEntries in pairs(layerData.equivalenceClasses.classes) do
                local classPosition = computePosition(parentPositions, parents)
                for j=1,classEntries.count do
                    local entry = classEntries[j]
                    positions[entry] = classPosition
                    newOrder:pushBack(entry)
                end
            end
            newOrder:sort(positions)
        end
        -- 2) roots
        local roots = layerData.equivalenceClasses.roots
        if roots.count > 0 then
            local optimizer = CouplingScoreOptimizer.new{
                couplings = layerData.couplings,
                order = OrderedSet.newFromArray(newOrder)
            }
            sortByHighestCouplingCoefficient(roots, layerData.couplings)
            for i=1,roots.count do
                local root = roots[i]
                optimizer:insertAnywhere(root)
            end
            newOrder:loadFromOrderedSet(optimizer.order)
        end
        -- 3) secondPass
        local positions = ErrorOnInvalidRead.new()
        for pos=1,newOrder.count do
            positions[newOrder[pos]] = pos
        end
        for entry,parent in pairs(layerData.secondPass) do
            positions[entry] = positions[parent]
        end
        -- Layer sort
        self.layers:sortLayer(layerId, positions)
    end
end

-- Runs the sorting algorithm on a LayersBuilder object.
--
-- Args:
-- * layersBuilder: LayersBuilder object.
--
function LayersInitialSorter.run(layersBuilder)
    local self = ErrorOnInvalidRead.new{
        channelLayers = layersBuilder:generateChannelLayers(),
        layers = layersBuilder.layers,
        layersSortingData = ErrorOnInvalidRead.new(),
    }

    parseInput(self)
    createCouplings(self)
    sortLayers(self)
end

return LayersInitialSorter
