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

local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local SinkCache = require("lua/model/SinkCache")
local TransformsDatabase = require("lua/model/TransformsDatabase")

describe("SinkCache", function()
    local factorio
    local intermediates
    local transforms
    setup(function()
        local rawData = {
            item = {
                normalSinked = {type = "item", name = "normalSinked"},
                notSinked = {type = "item", name = "notSinked"},
            },
            fluid = {
                recursiveSinked = {type = "fluid", name = "recursiveSinked"},
            },
            recipe = {
                normalSink = {
                    type = "recipe",
                    name = "normalSink",
                    ingredients = {
                        {type = "item", name = "normalSinked", amount = 1},
                    },
                    results = {},
                },
                recursiveSink = {
                    type = "recipe",
                    name = "recursiveSink",
                    ingredients = {
                        {type = "fluid", name = "recursiveSinked", amount = 1},
                    },
                    results = {
                        {type = "fluid", name = "recursiveSinked", amount = 1, probability = 0.9},
                    },
                }
            },
        }
        for i=1,32 do
            local name = "item"..i
            rawData.item[name] = {type = "item", name = name}
        end
        for i=1,30 do
            local name = "recursive"..i
            rawData.recipe[name] = {
                type = "recipe",
                name = name,
                ingredients = {
                    {type = "item", name = "item"..i, amount = 1},
                },
                results = {
                    {type = "fluid", name = "recursiveSinked", amount = 10},
                },
            }
        end
        for i=1,32 do
            local name = "normal"..i
            rawData.recipe[name] = {
                type = "recipe",
                name = name,
                ingredients = {
                    {type = "item", name = "item"..i, amount = 1 + (i % 3)},
                },
                results = {
                    {type = "item", name = "normalSinked", amount = 1},
                },
            }
        end
        for i=1,16 do
            local name = "not"..i
            rawData.recipe[name] = {
                type = "recipe",
                name = name,
                ingredients = {
                    {type = "item", name = "item"..i, amount = 1},
                },
                results = {
                    {type = "item", name = "notSinked", amount = 1},
                },
            }
        end
        factorio = MockFactorio.make{
            rawData = rawData,
        }

        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(factorio.game)
        transforms = TransformsDatabase.new{
            intermediates = intermediates,
        }
        transforms:rebuild(factorio.game)
    end)

    local object
    before_each(function()
        object = SinkCache.new{
            transforms = transforms,
        }
    end)

    it(".new()", function()
        assert.is_not_nil(object.indirectThresholds.normal)
    end)

    it(".setmetatable()", function()
        object:rebuild()
        SaveLoadTester.run{
            objects = {
                cache = object,
                intermediates = intermediates,
                transforms = transforms,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                TransformsDatabase.setmetatable(objects.transforms)
                SinkCache.setmetatable(objects.cache)
            end,
        }
    end)

    it(":rebuild()", function()
        object:rebuild()
        for i=1,30 do
            local recipe = transforms.recipe["recursive"..i]
            assert.are.equals(object.indirectThresholds.recursive[recipe], 30)
            assert.is_nil(rawget(object.indirectThresholds.normal, recipe))
        end
        for i=1,32 do
            local recipe = transforms.recipe["normal"..i]
            local threshold
            if ((i % 3) == 0) then
                threshold = 10
            else
                threshold = 11
            end
            assert.are.equals(object.indirectThresholds.normal[recipe], threshold)
            assert.is_nil(rawget(object.indirectThresholds.recursive, recipe))
        end
        for i=1,16 do
            local recipe = transforms.recipe["not"..i]
            assert.is_nil(rawget(object.indirectThresholds.normal, recipe))
            assert.is_nil(rawget(object.indirectThresholds.recursive, recipe))
        end
    end)
end)
