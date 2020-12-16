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
local FlyweightFactory = require("lua/class/FlyweightFactory")
local IndirectSinkBucketIndex = require("lua/model/IndirectSinkBucketIndex")
local Set = require("lua/containers/Set")

local cLogger = ClassLogger.new{className = "SinkCache"}

local initThresholds
local makeBuckets
local Metatable

-- Class parsing transforms for sink detection, and storing intermediate results.
--
-- The main purpose
--
-- RO Fields:
-- * transforms: TransformsDatabase. Transforms to parse.
-- * indirectThresholds: table. Gives the "indirect sink" score of a transform.
-- ** normal[AbstractTransform]: int or nil.
-- ** recursive[AbstractTransform]: int or nil.
--
local SinkCache = ErrorOnInvalidRead.new{
    -- Minimum size of cached indirect buckets (smaller are discarded).
    MinBucketSize = 8,

    -- Creates a new SinkCache object.
    --
    -- Args:
    -- * object: table.
    --
    -- Returns: SinkCache. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertField(object, "transforms")
        initThresholds(object)
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of an SinkCache object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        ErrorOnInvalidRead.setmetatable(object.indirectThresholds, nil, ErrorOnInvalidRead.setmetatable)
    end,
}

-- Metatable of the SinkCache class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Resets the content of the cache.
        --
        -- Args:
        -- * self: SinkCache.
        --
        rebuild = function(self)
            local sinkable = {}
            local sinkableByType = {
                normal = {},
                recursive = {},
            }
            self.transforms:forEach(function(transform)
                local sinkType = transform:getSinkType()
                if sinkType ~= "none" then
                    local sinked = next(transform.ingredients)
                    sinkableByType[sinkType][sinked] = true
                    sinkable[sinked] = true
                end
            end)

            local indirectThresholds = initThresholds(self)
            local producersOf = self.transforms.producersOf
            for sinked in pairs(sinkable) do
                local producers = producersOf[sinked]
                if producers then
                    local buckets = makeBuckets(producers, sinked)
                    for _,transforms in pairs(buckets) do
                        local indirectSinkedSet = {}
                        local indirectSinkedCount = 0
                        for transform in pairs(transforms) do
                            local ingredient = next(transform.ingredients)
                            if not indirectSinkedSet[ingredient] then
                                indirectSinkedCount = indirectSinkedCount + 1
                                indirectSinkedSet[ingredient] = true
                            end
                        end
                        if indirectSinkedCount >= SinkCache.MinBucketSize then
                            for sinkType,thresholds in pairs(indirectThresholds) do
                                if sinkableByType[sinkType][sinked] then
                                    for transform in pairs(transforms) do
                                        thresholds[transform] = math.max(rawget(thresholds, transform) or 0, indirectSinkedCount)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end,
    },
}

-- Resets the indirectThresholds field.
--
-- Args:
-- * self: SinkCache.
--
-- Returns: table. The new `indirectThresholds` value.
--
initThresholds = function(self)
    local result = ErrorOnInvalidRead.new{
        normal = ErrorOnInvalidRead.new(),
        recursive = ErrorOnInvalidRead.new(),
    }
    self.indirectThresholds = result
    return result
end

-- Computes the buckets of indirect sink transforms to a given sinkable intermediate.
--
-- Args:
-- * producers: Set<AbstractTransform>. Producers of the sinked intermediates.
-- * sinked: Intermediate. Item/fluid that has a direct sink.
--
-- Returns: Map<IndirectSinkBucketIndex,Set<AbstractTransform>>. The generated buckets.
--
makeBuckets = function(producers, sinked)
    local result = {}
    local bucketIndexFactory = FlyweightFactory.new{
        make = IndirectSinkBucketIndex.copy,
        valueEquals = IndirectSinkBucketIndex.equals,
    }
    for transform in pairs(producers) do
        local ingredients = transform.ingredients
        local i1,c1 = next(ingredients)
        if i1 and not next(ingredients, i1) then
            local products = transform.products
            if next(products) == sinked and not next(products, sinked) then
                local bucketIndex = bucketIndexFactory:get{
                    products = transform.products,
                    iAmount = c1,
                }
                if result[bucketIndex] then
                    result[bucketIndex][transform] = true
                else
                    result[bucketIndex] = {
                        [transform] = true,
                    }
                end
            end
        end
    end
    return result
end

return SinkCache
