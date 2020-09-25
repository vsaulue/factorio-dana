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
local Set = require("lua/containers/Set")
local TableUtils = require("lua/containers/TableUtils")

local cLogger = ClassLogger.new{className = "SimpleCyclesDatabase"}

local processIntermediates
local Metatable

local getOrInitTableField = TableUtils.getOrInitTableField

-- Database holding some of the simple cycles of a TransformsDatabase.
--
-- Two transforms A & B forms a simple cycle if:
-- * A.ingredients & B.products hold the same intermediates.
-- * B.ingredients & A.products hold the same intermediates.
-- * The aforementioned sets are not empty.
--
-- Right now, only cycles where one of the set contains exacly 1 intermediate are stored.
--
-- RO Fields:
-- * nonPositive[transform] -> Set of AbstractTransform. Gives all the transforms defining a non-positive
--     cycle with `transform`. If `transform` has no non-positive reverse, the map's value may be nil.
-- * transforms: TransformsDatabase object holding all the transforms.
--
local SimpleCyclesDatabase = ErrorOnInvalidRead.new{
    -- Creates a new SimpleCyclesDatabase object.
    --
    -- Args:
    -- * object: Table to turn into a SimpleCyclesDatabase object (required field: transform).
    --
    -- Returns: The argument turned into a SimpleCyclesDatabase object.
    new = function(object)
        cLogger:assertField(object, "transforms")
        object.nonPositive = {}
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a SimpleCyclesDatabase object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the SimpleCyclesDatabase class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Resets the content of the database.
        --
        -- Args:
        -- * self: SimpleCyclesDatabase object.
        --
        rebuild = function(self)
            self.nonPositive = {}

            local intermediates = self.transforms.intermediates
            processIntermediates(self, intermediates.item)
            processIntermediates(self, intermediates.fluid)
        end,
    }
}

-- Parses cycles starting from specific intermediates.
--
-- This function does NOT look for cycles involving all the given intermediates at once. It takes the intermediates
-- one by one, and looks for cycles involving this single intermediate.
--
-- Args:
-- * self: SimpleCyclesDatabase object.
-- * intermediates[_] -> Intermediate: Intermediates to consider.
--
processIntermediates = function(self, intermediates)
    local consumersOf = self.transforms.consumersOf
    local producersOf = self.transforms.producersOf
    local nonPositive = self.nonPositive
    for _,intermediate in pairs(intermediates) do
        local consumers = consumersOf[intermediate]
        local producers = producersOf[intermediate]
        if producers and consumers then
            for producer in pairs(producers) do
                if Set.checkSingleton(producer.products, intermediate) and next(producer.ingredients) then
                    for consumer in pairs(consumers) do
                        if producer:isNonPositiveCycleWith(consumer) then
                            getOrInitTableField(nonPositive, producer)[consumer] = true
                            getOrInitTableField(nonPositive, consumer)[producer] = true
                        end
                    end
                end
            end
        end
    end
end

return SimpleCyclesDatabase
