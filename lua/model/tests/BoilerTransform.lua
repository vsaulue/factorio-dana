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

local BoilerTransform = require("lua/model/BoilerTransform")
local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local Logger = require("lua/logger/Logger")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("BoilerTransform", function()
    local rawData
    local gameScript
    local intermediates

    setup(function()
        rawData = {
            boiler = {
                boilerA = {
                    energy_source = {
                        type = "void",
                    },
                    fluid_box = {
                        production_type = "input",
                        filter = "water",
                    },
                    name = "boilerA",
                    output_fluid_box = {
                        production_type = "output",
                        filter = "steam",
                    },
                    type = "boiler",
                },
                boilerB = {
                    energy_source = {
                        type = "burner",
                    },
                    fluid_box = {
                        production_type = "input",
                        -- filter = "water",
                    },
                    name = "boilerB",
                    output_fluid_box = {
                        production_type = "output",
                        filter = "steam",
                    },
                    type = "boiler",
                },
                boilerC = {
                    energy_source = {
                        type = "fluid",
                        fluid_box = {
                            production_type = "input-output",
                            filter = "gasoline",
                        }
                    },
                    fluid_box = {
                        production_type = "input",
                        filter = "water",
                    },
                    name = "boilerC",
                    output_fluid_box = {
                        production_type = "output",
                        filter = "steam",
                    },
                    type = "boiler",
                },
            },
            fluid = {
                gasoline = {type = "fluid", name = "gasoline"},
                steam = {type = "fluid", name = "steam"},
                water = {type = "fluid", name = "water"},
            },
        }
        gameScript = LuaGameScript.make(rawData)
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
    end)

    describe(".tryMake()", function()
        it("-- valid", function()
            local prototype = gameScript.entity_prototypes.boilerA
            local transform = BoilerTransform.tryMake(prototype, intermediates)
            assert.are.same(transform, {
                ingredients = {
                    [intermediates.fluid.water] = 1,
                },
                localisedName = {
                    "dana.model.transform.name",
                    {"dana.model.transform.boilerType"},
                    prototype.localised_name,
                },
                products = {
                    [intermediates.fluid.steam] = ProductData.make(ProductAmount.makeConstant(1)),
                },
                rawBoiler = prototype,
                spritePath = "entity/boilerA",
                type = "boiler",
            })
        end)

        it("-- no filter", function()
            local prototype = gameScript.entity_prototypes.boilerB
            local transform = BoilerTransform.tryMake(prototype, intermediates)
            assert.is_nil(transform)
        end)

        it("-- double input", function()
            stub(Logger, "warn")
            local prototype = gameScript.entity_prototypes.boilerC
            local transform = BoilerTransform.tryMake(prototype, intermediates)
            assert.stub(Logger.warn).was.called()
            assert.is_nil(transform)
        end)
    end)

    it(".setmetatable()", function()
        local prototype = gameScript.entity_prototypes.boilerA
        local transform = BoilerTransform.tryMake(prototype, intermediates)
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                transform = transform,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                BoilerTransform.setmetatable(objects.transform)
            end,
        }
    end)
end)
