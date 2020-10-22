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

local MinableProperties = require("lua/testing/mocks/MinableProperties")

describe("MinableProperties", function()
    describe(".make()", function()
        it("-- nil", function()
            local object = MinableProperties.make(nil)
            assert.are.same(object, {
                minable = false,
            })
        end)

        it("-- no result", function()
            local object = MinableProperties.make{}
            assert.are.same(object, {
                minable = true,
            })
        end)

        it("-- .results", function()
            local object = MinableProperties.make{
                results = {
                    {"iron-ore", 5},
                    {type = "item", name = "copper-ore", amount_min = 2, amount_max = 4, probability = 0.25},
                },
            }
            assert.are.same(object, {
                minable = true,
                products = {
                    {type = "item", name = "iron-ore", amount = 5},
                    {type = "item", name = "copper-ore", amount_min = 2, amount_max = 4, probability = 0.25},
                }
            })
        end)

        it("-- .result", function()
            local object = MinableProperties.make{
                result = "iron-ore",
            }
            assert.are.same(object, {
                minable = true,
                products = {
                    {type = "item", name = "iron-ore", amount = 1},
                },
            })
        end)

        it("-- .result & .count", function()
            local object = MinableProperties.make{
                result = "copper-ore",
                count = 256,
            }
            assert.are.same(object, {
                minable = true,
                products = {
                    {type = "item", name = "copper-ore", amount = 256},
                },
            })
        end)

        it("-- .required_fluid", function()
            local object = MinableProperties.make{
                required_fluid = "water",
            }
            assert.are.same(object, {
                minable = true,
                required_fluid = "water",
                fluid_amount = 0,
            })
        end)

        it("-- .required_fluid + .fluid_amount", function()
            local object = MinableProperties.make{
                required_fluid = "water",
                fluid_amount = 11,
            }
            assert.are.same(object, {
                minable = true,
                required_fluid = "water",
                fluid_amount = 11,
            })
        end)

        it("-- invalid .required_fluid", function()
            assert.error(function()
                MinableProperties.make{
                    required_fluid = 123,
                }
            end)
        end)

        it("-- invalid .fluid_amount", function()
            assert.error(function()
                MinableProperties.make{
                    required_fluid = "steam",
                    fluid_amount = "5",
                }
            end)
        end)
    end)
end)
