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

local AppTestbench = require("lua/testing/AppTestbench")
local SinkFilterStep = require("lua/query/steps/SinkFilterStep")
local FullGraphQuery = require("lua/query/Fullgraphquery")
local SelectionStep = require("lua/query/steps/Selectionstep")

describe("SinkFilterStep", function()
    local appTestbench
    setup(function()
        local rawData = {
            fluid = {
                water = {type = "fluid", name = "water"},
            },
            item = {
                ash = {type = "item", name = "ash"},
            },
            recipe = {
                ashSink = {
                    type = "recipe",
                    name = "ashSink",
                    ingredients = {
                        {type = "item", name = "ash", amount = 1},
                    },
                    results = {
                        {type = "item", name = "ash", amount = 1, probability = 0.5},
                    },
                },
                waterSink = {
                    type = "recipe",
                    name = "waterSink",
                    ingredients = {
                        {type = "fluid", name = "water", amount = 1},
                    },
                    results = {},
                },
            }
        }
        for i=1,35 do
            local itemName = "item"..i
            rawData.item[itemName] = {type = "item", name = itemName}

            local recursiveName = "recursive"..i
            rawData.recipe[recursiveName] = {
                type = "recipe",
                name = recursiveName,
                ingredients = {
                    {type = "item", name = itemName, amount = 1},
                },
                results = {
                    {type = "item", name = "ash", amount = 1},
                },
            }
        end
        for i=1,17 do
            local normalName = "normal"..i
            rawData.recipe[normalName] = {
                type = "recipe",
                name = normalName,
                ingredients = {
                    {type = "item", name = "item"..i, amount = 1},
                },
                results = {
                    {type = "fluid", name = "water", amount = 50},
                },
            }
        end
        appTestbench = AppTestbench.make{
            rawData = rawData,
        }
    end)

    describe(".run()", function()
        local query
        before_each(function()
            query = FullGraphQuery.new()
        end)

        local runFilter = function()
            local graph = SelectionStep.run(query, appTestbench.force)
            SinkFilterStep.run(query, appTestbench.force, graph)
            return graph
        end

        local t = appTestbench.prototypes.transforms
        local makeEdgeMap = function(transforms)
            local result = {}
            for transform in pairs(transforms) do
                result[transform] = {
                    index = transform,
                    inbound = transform.ingredients,
                    outbound = transform.products,
                }
            end
            return result
        end

        it("-- recursive indirect sink filter", function()
            query.sinkParams.filterRecursive = true
            query.sinkParams.indirectThreshold = 30
            local graph = runFilter()

            local expectedEdges = {
                [t.recipe.waterSink] = true,
            }
            for i=1,17 do
                expectedEdges[t.recipe["normal"..i]] = true
            end
            assert.are.same(graph.edges, makeEdgeMap(expectedEdges))
        end)

        it("-- normal indirect sink filter", function()
            query.sinkParams.filterNormal = true
            query.sinkParams.indirectThreshold = 15
            local graph = runFilter()

            local expectedEdges = {
                [t.recipe.ashSink] = true,
            }
            for i=1,35 do
                expectedEdges[t.recipe["recursive"..i]] = true
            end
            assert.are.same(graph.edges, makeEdgeMap(expectedEdges))
        end)
    end)
end)
