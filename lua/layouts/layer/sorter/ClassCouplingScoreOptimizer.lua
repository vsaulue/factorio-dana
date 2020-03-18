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

local Couplings = require("lua/layouts/layer/sorter/Couplings")
local CouplingScoreOptimizer = require("lua/layouts/layer/sorter/CouplingScoreOptimizer")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local OrderedSet = require("lua/containers/OrderedSet")

-- Algorithm to sort entries within equivalence classes, to optimize the coupling score.
--
local ClassCouplingScoreOptimizer = ErrorOnInvalidRead.new{
    run = nil, -- implemented later
}

-- Generates a Couplings object, holding coefficients between classes and entries.
--
-- Args:
-- * classArray: Array of classes, for which coupling coefficient are generated.
-- * entryCouplings: Couplings object, holding coefficients between all entries in the classArray.
--
local function generateClassCouplings(classArray, entryCouplings)
    local result = Couplings.new()
    local entryToClass = ErrorOnInvalidRead.new()
    for i=1,classArray.count do
        local class = classArray[i]
        result:newElement(class)
        for j=1,class.count do
            local entry = class[j]
            result:newElement(entry)
            entryToClass[entry] = class
        end
    end
    for i=1,entryCouplings.order.count do
        local entryI = entryCouplings.order[i]
        local classI = rawget(entryToClass, entryI)
        if classI then
            for entryJ,coef in pairs(entryCouplings[entryI]) do
                local classJ = rawget(entryToClass, entryJ)
                if classJ then
                    if classI ~= classJ then
                        result:addToCoupling(classI, classJ, coef)
                        result:addToCoupling(classI, entryJ, coef)
                        result:addToCoupling(entryI, classJ, coef)
                    else
                        result:addToCoupling(entryI, entryJ, coef)
                    end
                end
            end
        end
    end
    return result
end

-- Generates a radius map for each classes and entries.
--
-- Args:
-- * classArray: Array of classes.
--
-- Returns: a map indexed by classes or entries, giving their radiuses.
--
local function generateRadiuses(classArray)
    local result = ErrorOnInvalidRead.new()
    for i=1,classArray.count do
        local class = classArray[i]
        local classCount = class.count
        result[class] = classCount
        for j=1,class.count do
            result[class[j]] = 1
        end
    end
    return result
end

-- Runs the sorting algorithm on an array of equivalence classes.
--
-- Args:
-- * classArray: Array of classes, on which the algorithm will be run.
-- * entryCouplings: Couplings object, holding coefficients between all entries in the classArray.
--
function ClassCouplingScoreOptimizer.run(classArray, entryCouplings)
    local classCouplings = generateClassCouplings(classArray, entryCouplings)
    local radiuses = generateRadiuses(classArray)
    local order = OrderedSet.newFromArray(classArray)
    for i=1,classArray.count do
        local currentClass = classArray[i]
        local lowBound = order.backward[currentClass]
        local highBound = order.forward[currentClass]
        order:remove(currentClass)

        local optimizer = CouplingScoreOptimizer.new{
            couplings = classCouplings,
            order = order,
            radiuses = radiuses,
        }
        optimizer:insertMany(lowBound, highBound, currentClass)

        local it = order.forward[lowBound]
        local i = 1
        while it ~= highBound do
            currentClass[i] = it
            local next = order.forward[it]
            order:remove(it)
            it = next
            i = i + 1
        end
        order:insertAfter(lowBound, currentClass)
    end
end

return ClassCouplingScoreOptimizer
