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
local ClassCouplingScoreOptimizer = require("lua/layouts/layer/sorter/ClassCouplingScoreOptimizer")
local Couplings = require("lua/layouts/layer/sorter/Couplings")
local CouplingScoreOptimizer = require("lua/layouts/layer/sorter/CouplingScoreOptimizer")
local EquivalenceClasses = require("lua/layouts/layer/sorter/EquivalenceClasses")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local OrderedSet = require("lua/containers/OrderedSet")

local computeCouplings
local computePosition
local createCouplings
local parseInput
local sortLayers

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
local LayersSorter = ErrorOnInvalidRead.new{
    -- Runs the sorting algorithm on a Layers object.
    --
    -- Args:
    -- * layers: Layers object.
    --
    run = function(layers)
        local self = ErrorOnInvalidRead.new{
            channelLayers = layers:generateChannelLayers(),
            layers = layers,
            layersSortingData = ErrorOnInvalidRead.new(),
        }

        parseInput(self)
        createCouplings(self)
        sortLayers(self)
    end,
}

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
-- * self: LayersSorter object.
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
                children[entry] = entry.lowSlots
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
-- * self: LayersSorter object.
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
            local rootEntry = nil
            for i=1,highEntries.count do
                local entry = highEntries[i]
                if channelIndex.rootNodeIndex == entry.index then
                    rootEntry = entry
                end
            end
            if rootEntry then
                for i=1,highEntries.count do
                    local entry = highEntries[i]
                    if entry ~= rootEntry then
                        layerData.secondPass[entry] = rootEntry
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

-- Run the sorting algorithm on each layers.
--
-- Sorting is done layer by layer, following this a multi-step pipeline:
-- * 1) Greedily place firstPass entries, at the barycenter of their inbound LayerLinkIndex set.
-- * 2) Insert roots, by trying to minimize couplings score of the layer.
-- * 3) Places secondPass entries, as barycenter of their parents.
--
-- Between each step of the pipeline, the result is consolidated in an array. The next step
-- uses the rank of entries from the previous step as positions.
--
-- Args:
-- * self: LayersSorter object.
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
            local classes = layerData.equivalenceClasses.classes
            local parentPositions = ErrorOnInvalidRead.new()
            local positions = ErrorOnInvalidRead.new()
            for rank=1,prevLayer.count do
                local entry = prevLayer[rank]
                parentPositions[entry] = rank
            end
            for channelIndex,lowEntries in pairs(layerData.lowChannels) do
                parentPositions[channelIndex] = computePosition(parentPositions, lowEntries)
            end
            local classPositions = ErrorOnInvalidRead.new()
            local classesArray = Array.new()
            for parents,classEntries in pairs(classes) do
                classPositions[classEntries] = computePosition(parentPositions, parents)
                classesArray:pushBack(classEntries)
            end
            classesArray:sort(classPositions)
            ClassCouplingScoreOptimizer.run(classesArray, layerData.couplings)
            for i=1,classesArray.count do
                local classEntries = classesArray[i]
                for j=1,classEntries.count do
                    newOrder:pushBack(classEntries[j])
                end
            end
        end
        -- 2) roots
        local roots = layerData.equivalenceClasses.roots
        local radiuses = ErrorOnInvalidRead.new()
        for i=1,layer.count do
            radiuses[layer[i]] = 1
        end
        local optimizer = CouplingScoreOptimizer.new{
            couplings = layerData.couplings,
            order = OrderedSet.newFromArray(newOrder),
            radiuses = radiuses,
        }
        if roots.count > 0 then
            optimizer:insertManyAnywhere(roots)
        end
        -- 3) secondPass
        for entry,parent in pairs(layerData.secondPass) do
            optimizer:insertAround(parent, entry)
        end
        -- Layer sort
        local positions = optimizer:generatePositions()
        self.layers:sortLayer(layerId, positions)
    end
end

return LayersSorter
