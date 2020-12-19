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

local AbstractQuery = require("lua/query/AbstractQuery")
local AppTestbench = require("lua/testing/AppTestbench")
local FullGraphQuery = require("lua/query/fullgraphquery")
local SelectionStep = require("lua/query/steps/SelectionStep")

describe("SelectionStep", function()
    local appTestbench
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {
                boiler = {
                    boiler = {
                        energy_source = {
                            type = "void",
                        },
                        fluid_box = {
                            production_type = "input",
                            filter = "water",
                        },
                        name = "boiler",
                        output_fluid_box = {
                            production_type = "output",
                            filter = "steam",
                        },
                        type = "boiler",
                    },
                },
                fluid = {
                    steam = {type = "fluid", name = "steam"},
                    water = {type = "fluid", name = "water"},
                },
                item = {
                    ash = {type = "item", name = "ash"},
                    wood = {
                        type = "item",
                        name = "wood",
                        burnt_result = "ash",
                    },
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
                        }
                    },
                    steamSink = {
                        type = "recipe",
                        name = "steamSink",
                        ingredients = {
                            {type = "fluid", name = "steam", amount = 10},
                        },
                        results = {},
                    },
                },
                resource = {
                    woodOre = {
                        type = "resource",
                        name = "woodOre",
                        minable = {
                            result = "wood",
                            count = 1,
                        },
                    },
                },
            },
        }
    end)

    local query
    before_each(function()
        query = FullGraphQuery.new{
            sinkParams = {
                filterNormal = false,
                filterRecursive = false,
                indirectThreshold = 64,
            },
        }
    end)

    describe(".run()", function()
        local t = appTestbench.prototypes.transforms
        local makeEdgeMap = function(transforms)
            local result = {}
            for _,transform in ipairs(transforms) do
                result[transform] = {
                    index = transform,
                    inbound = transform.ingredients,
                    outbound = transform.products,
                }
            end
            return result
        end

        it("-- no sink filter", function()
            local graph = SelectionStep.run(query, appTestbench.force)
            assert.are.same(graph.edges, makeEdgeMap{
                t.boiler.boiler,
                t.fuel.wood,
                t.recipe.ashSink,
                t.recipe.steamSink,
            })
        end)

        it("-- normal sink filter", function()
            query.sinkParams.filterNormal = true
            local graph = SelectionStep.run(query, appTestbench.force)
            assert.are.same(graph.edges, makeEdgeMap{
                t.boiler.boiler,
                t.fuel.wood,
                t.recipe.ashSink,
            })
        end)

        it("-- recursive sink filter", function()
            query.sinkParams.filterRecursive = true
            local graph = SelectionStep.run(query, appTestbench.force)
            assert.are.same(graph.edges, makeEdgeMap{
                t.boiler.boiler,
                t.fuel.wood,
                t.recipe.steamSink,
            })
        end)
    end)
end)
