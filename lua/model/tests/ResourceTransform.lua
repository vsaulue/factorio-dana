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
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local ResourceTransform = require("lua/model/ResourceTransform")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ResourceTransform", function()
    local gameScript
    local intermediates
    setup(function()
        gameScript = LuaGameScript.make{
            fluid = {
                steam = {type = "fluid", name = "steam"},
            },
            item = {
                coal = {type = "item", name = "coal"},
            },
            resource = {
                coal = {
                    type = "resource",
                    name = "coal",
                    minable = {
                        result = "coal",
                        count = 1,
                    },
                },
                indestructible = {
                    type = "resource",
                    name = "indestructible",
                },
                noResult = {
                    type = "resource",
                    name = "noResult",
                    minable = {},
                },
                steamedCoal = {
                    type = "resource",
                    name = "steamedCoal",
                    minable = {
                        result = "coal",
                        count = 5,
                        required_fluid = "steam",
                        fluid_amount = 2,
                    },
                },
            },
        }
        intermediates = IntermediatesDatabase.new()
        intermediates:rebuild(gameScript)
    end)

    describe(".tryMake()", function()
        it("-- not minable", function()
            local prototype = gameScript.entity_prototypes.indestructible
            local object = ResourceTransform.tryMake(prototype, intermediates)
            assert.is_nil(object)
        end)

        it("-- no result", function()
            local prototype = gameScript.entity_prototypes.noResult
            local object = ResourceTransform.tryMake(prototype, intermediates)
            assert.is_nil(object)
        end)

        it("-- no fluid", function()
            local prototype = gameScript.entity_prototypes.coal
            local object = ResourceTransform.tryMake(prototype, intermediates)

            assert.are.same(object, {
                ingredients = {},
                localisedName = {
                    "dana.model.transform.name",
                    {"dana.model.transform.resourceType"},
                    {"entity-name.coal"},
                },
                products = {
                    [intermediates.item.coal] = ProductData.make(ProductAmount.makeConstant(1))
                },
                rawResource = prototype,
                type = "resource",
                spritePath = "entity/coal",
            })
        end)

        it("-- fluid", function()
            local prototype = gameScript.entity_prototypes.steamedCoal
            local object = ResourceTransform.tryMake(prototype, intermediates)

            assert.are.same(object, {
                ingredients = {
                    [intermediates.fluid.steam] = 2,
                },
                localisedName = {
                    "dana.model.transform.name",
                    {"dana.model.transform.resourceType"},
                    {"entity-name.steamedCoal"},
                },
                products = {
                    [intermediates.item.coal] = ProductData.make(ProductAmount.makeConstant(5))
                },
                rawResource = prototype,
                type = "resource",
                spritePath = "entity/steamedCoal",
            })
        end)
    end)

    it(".setmetatable()", function()
        local prototype = gameScript.entity_prototypes.steamedCoal
        local object = ResourceTransform.tryMake(prototype, intermediates)
        SaveLoadTester.run{
            objects = {
                intermediates = intermediates,
                object = object,
            },
            metatableSetter = function(objects)
                IntermediatesDatabase.setmetatable(objects.intermediates)
                ResourceTransform.setmetatable(objects.object)
            end
        }
    end)
end)
