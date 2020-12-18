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
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local Set = require("lua/containers/Set")

describe("AbstractQuery", function()
    local appTestbench
    local myMetatable
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
                    barrel = {type = "item", name = "barrel"},
                    ironOre = {type = "item", name = "ironOre"},
                    ironPlate = {type = "item", name = "ironPlate"},
                    waterBarrel = {type = "item", name = "waterBarrel"},
                },
                ["offshore-pump"] = {
                    waterPump = {
                        type = "offshore-pump",
                        name = "waterPump",
                        fluid = "water",
                        fluid_box = {
                            production_type = "output",
                            filter = "water",
                        },
                        pumping_speed = 5,
                    },
                },
                recipe = {
                    barrel = {
                        type = "recipe",
                        name = "barrel",
                        ingredients = {
                            {type = "item", name = "ironPlate", amount = 5},
                        },
                        results = {
                            {type = "item", name = "barrel", amount = 1},
                        }
                    },
                    barrelSink = {
                        type = "recipe",
                        name = "barrelSink",
                        ingredients = {
                            {type = "item", name = "barrel", amount = 1},
                        },
                        results = {},
                    },
                    ironPlate = {
                        type = "recipe",
                        name = "ironPlate",
                        ingredients = {
                            {type = "item", name = "ironOre", amount = 1},
                        },
                        results = {
                            {type = "item", name = "ironPlate", amount = 1},
                        }
                    },
                    waterBarrel = {
                        type = "recipe",
                        name = "waterBarrel",
                        ingredients = {
                            {type = "fluid", name = "water", amount = 10},
                            {type = "item", name = "barrel", amount = 1},
                        },
                        results = {
                            {type = "item", name = "waterBarrel", amount = 1},
                        },
                    },
                },
                resource = {
                    ironOre = {
                        type = "resource",
                        name = "ironOre",
                        minable = {
                            result = "ironOre",
                            count = 1,
                        },
                    },
                },
            },
        }
        myMetatable = {}
    end)

    local query
    before_each(function()
        query = AbstractQuery.new({
            queryType = "test",
        }, myMetatable)
    end)

    it(".new()", function()
        assert.is_not_nil(query.sinkParams)
    end)

    it(".preprocess()", function()
        local graph,order = AbstractQuery.preprocess(query, appTestbench.force)

        local i = appTestbench.prototypes.intermediates
        assert.are.same(order, {
            [i.item.ironOre] = 0,
            [i.fluid.water] = 0,
            [i.fluid.steam] = 1,
            [i.item.ironPlate] = 1,
            [i.item.barrel] = 2,
            [i.item.waterBarrel] = 3,
        })

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
        assert.are.same(graph.edges, makeEdgeMap{
            t.boiler.boiler,
            t.recipe.barrel,
            t.recipe.ironPlate,
            t.recipe.waterBarrel,
        })
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = query,
            metatableSetter = function(objects)
                AbstractQuery.setmetatable(objects, myMetatable)
            end,
        }
    end)
end)
