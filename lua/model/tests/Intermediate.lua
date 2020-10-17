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

local Intermediate = require("lua/model/Intermediate")

local LuaFluidPrototype = require("lua/testing/mocks/LuaFluidPrototype")
local LuaItemPrototype = require("lua/testing/mocks/LuaItemPrototype")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("Intermediate", function()
    local woodPrototype = LuaItemPrototype.make{
        type = "item",
        name = "wood",
    }

    describe(".new()", function()
        it("-- valid fluid", function()
            local intermediate = Intermediate.new{
                rawPrototype = LuaFluidPrototype.make{
                    type = "fluid",
                    name = "water",
                },
                type = "fluid",
            }

            assert.are.same(intermediate.localisedName, {
                "dana.model.intermediate.name",
                {"dana.model.intermediate.fluidType"},
                {"fluid-name.water"},
            })

            assert.are.equals(intermediate.spritePath, "fluid/water")
        end)

        it("-- valid item", function()
            local intermediate = Intermediate.new{
                rawPrototype = woodPrototype,
                type = "item",
            }

            assert.are.same(intermediate.localisedName, {
                "dana.model.intermediate.name",
                {"dana.model.intermediate.itemType"},
                {"item-name.wood"},
            })

            assert.are.equals(intermediate.spritePath, "item/wood")
        end)

        it("-- missing type", function()
            assert.error(function()
                Intermediate.new{
                    rawPrototype = woodPrototype,
                }
            end)
        end)

        it("-- missing prototype", function()
            assert.error(function()
                Intermediate.new{
                    type = "item",
                }
            end)
        end)
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = Intermediate.new{
                rawPrototype = woodPrototype,
                type = "item",
            },
            metatableSetter = Intermediate.setmetatable,
        }
    end)
end)
