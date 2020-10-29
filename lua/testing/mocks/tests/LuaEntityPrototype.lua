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
        describe("-- boiler", function()
            local cArgs
            before_each(function()
                cArgs = {
                    type = "boiler",
                    name = "boiler",
                    energy_source = {
                        type = "void",
                    },
                    fluid_box = {
                        production_type = "input-output",
                        filter = "water",
                    },
                    output_fluid_box = {
                        production_type = "output",
                        filter = "steam",
                    },
                }
            end)

            it(", valid", function()
                local object = LuaEntityPrototype.make(cArgs)
                assert.are.same(MockObject.getData(object), {
                    fluidbox_prototypes = {
                        MockObject.make{production_type = "input-output", filter = "water"},
                        MockObject.make{production_type = "output", filter = "steam"},
                    },
                    localised_name = {"entity-name.boiler"},
                    mineable_properties = {
                        minable = false,
                    },
                    name = "boiler",
                    type = "boiler",
                })
            end)

            it(", valid + fluid energy_source", function()
                cArgs.energy_source = {
                    type = "fluid",
                    fluid_box = {
                        production_type = "input-output",
                        filter = "light-oil",
                    },
                }
                local object = LuaEntityPrototype.make(cArgs)
                assert.are.same(MockObject.getData(object).fluidbox_prototypes, {
                    MockObject.make{production_type = "input-output", filter = "water"},
                    MockObject.make{production_type = "output", filter = "steam"},
                    MockObject.make{production_type = "input-output", filter = "light-oil"},
                })
                assert.are.same(MockObject.getData(object).fluid_energy_source_prototype, MockObject.make{
                    fluid_box = MockObject.make{production_type = "input-output", filter = "light-oil"},
                })
            end)

            it(", no fluid_box", function()
                cArgs.fluid_box = nil
                assert.error(function()
                    LuaEntityPrototype.make(cArgs)
                end)
            end)

            it(", no output_fluid_box", function()
                cArgs.output_fluid_box = nil
                assert.error(function()
                    LuaEntityPrototype.make(cArgs)
                end)
            end)

            it(", no energy_source", function()
                cArgs.energy_source = nil
                assert.error(function()
                    LuaEntityPrototype.make(cArgs)
                end)
            end)
        end)

        describe("-- offshore-pump", function()
            it(", valid", function()
                local object = LuaEntityPrototype.make{
                    type = "offshore-pump",
                    name = "water-pump",
                    fluid = "water",
                    fluid_box = {
                        production_type = "output",
                    },
                    pumping_speed = 1200,
                }
                assert.are.same(MockObject.getData(object), {
                    fluid = "water",
                    fluidbox_prototypes = {
                        MockObject.make{production_type = "output"},
                    },
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
                fluidbox_prototypes = {},
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

    describe(":fluid_energy_source_prototype", function()
        local object
        before_each(function()
            object = LuaEntityPrototype.make{
                type = "boiler",
                name = "boiler",
                energy_source = {
                    type = "void",
                },
                fluid_box = {
                    production_type = "input-output",
                    filter = "water",
                },
                output_fluid_box = {
                    production_type = "output",
                    filter = "steam",
                },
            }
        end)

        it("-- read", function()
            local energySource = object.fluid_energy_source_prototype
            assert.are.equals(energySource, MockObject.getData(object).fluid_energy_source_prototype)
        end)

        it("-- write", function()
            assert.error(function()
                object.fluid_energy_source_prototype = "denied"
            end)
        end)
    end)

    describe(":fluidbox_prototypes", function()
        local object
        before_each(function()
            object = LuaEntityPrototype.make{
                type = "offshore-pump",
                name = "waterPump",
                fluid = "water",
                pumping_speed = 5,
                fluid_box = {
                    production_type = "input-output",
                }
            }
        end)

        it("-- read", function()
            assert.are.same(MockObject.getData(object).fluidbox_prototypes, object.fluidbox_prototypes)
        end)

        it("-- write", function()
            assert.error(function()
                object.fluidbox_prototypes = "denied"
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
