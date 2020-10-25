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
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local OffshorePumpTransform = require("lua/model/OffshorePumpTransform")
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("OffshorePumpTransform", function()
    local gameScript
    local intermediates

    setup(function()
        gameScript = LuaGameScript.make{
            fluid = {
                water = {
                    type = "fluid",
                    name = "water",
                },
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
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
    end)

    it(".make()", function()
        local prototype = gameScript.entity_prototypes.waterPump
        local object = OffshorePumpTransform.make(prototype, intermediates)
        assert.are.same(object, {
            ingredients = {},
            localisedName = {
                "dana.model.transform.name",
                {"dana.model.transform.offshorePumpType"},
                prototype.localised_name,
            },
            products = {
                [intermediates.fluid.water] = ProductData.make(ProductAmount.makeConstant(300)),
            },
            rawPump = prototype,
            spritePath = "entity/waterPump",
            type = "offshorePump",
        })
    end)

    it(".setmetatable()", function()
        local prototype = gameScript.entity_prototypes.waterPump
        local object = OffshorePumpTransform.make(prototype, intermediates)

        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                object = object,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                OffshorePumpTransform.setmetatable(objects.object)
            end,
        }
    end)
end)
