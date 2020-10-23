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

local LuaEntityPrototype = require("lua/testing/mocks/LuaEntityPrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaEntityPrototype", function()
    describe(".make()", function()
        describe("-- offshore-pump", function()
            it(", valid", function()
                local object = LuaEntityPrototype.make{
                    type = "offshore-pump",
                    name = "water-pump",
                    fluid = "water",
                    pumping_speed = 1200,
                }
                assert.are.same(MockObject.getData(object), {
                    fluid = "water",
                    localised_name = {"entity-name.water-pump"},
                    mineable_properties = {
                        minable = false,
                    },
                    name = "water-pump",
                    pumping_speed = 1200,
                    type = "offshore-pump",
                })
            end)

            it(", missing fluid", function()
                assert.error(function()
                    LuaEntityPrototype.make{
                        type = "offshore-pump",
                        name = "water-pump",
                        -- fluid = "water",
                        pumping_speed = 1200,
                    }
                end)
            end)

            it(", missing pumping_speed", function()
                assert.error(function()
                    LuaEntityPrototype.make{
                        type = "offshore-pump",
                        name = "water-pump",
                        fluid = "water",
                        -- pumping_speed = 1200,
                    }
                end)
            end)
        end)

        it("-- resource", function()
            local object = LuaEntityPrototype.make{
                type = "resource",
                name = "john-snow-knowledge",
                -- minable = nil,   for some reason, it yields nothing
            }
            assert.are.same(MockObject.getData(object),{
                type = "resource",
                name = "john-snow-knowledge",
                localised_name = {"entity-name.john-snow-knowledge"},
                mineable_properties = {
                    minable = false,
                },
            })
        end)

        it("-- invalid type", function()
            assert.error(function()
                LuaEntityPrototype.make{
                    type = "item",
                    name = "minigun",
                }
            end)
        end)
    end)

    describe(":mineable_properties", function()
        local object
        before_each(function()
            object = LuaEntityPrototype.make{
                type = "resource",
                name = "iron-ore",
                minable = {
                    result = "iron-ore",
                    count = 5,
                }
            }
        end)

        it("-- make", function()
            assert.are.equals(getmetatable(object).className, "LuaEntityPrototype")
            local props = MockObject.getData(object).mineable_properties
            assert.are.same(props, {
                minable = true,
                products = {
                    {type="item", name = "iron-ore", amount = 5},
                },
            })
        end)

        it("-- read", function()
            local internal = MockObject.getData(object).mineable_properties
            local read = object.mineable_properties
            assert.are.same(internal, read)
            read.products[1].name = "copper-ore"
            assert.are.equals(internal.products[1].name, "iron-ore")
        end)

        it("-- write", function()
            assert.error(function()
                object.mineable_properties = "denied"
            end)
        end)
    end)
end)
