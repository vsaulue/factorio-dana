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

local Product = require("lua/testing/mocks/Product")

describe("Product.make()", function()
    it("-- valid short", function()
        local product = Product.make{"wood",4}
        assert.are.same(product, {
            type = "item",
            name = "wood",
            amount = 4,
        })
    end)

    it("-- valid long item", function()
        local product = Product.make{
            type = "item",
            name = "wood",
            amount = 4,
        }
        assert.are.same(product, {
            type = "item",
            name = "wood",
            amount = 4,
        })
    end)

    it("-- valid long, implicit item", function()
        local product = Product.make{
            name = "wood",
            amount = 3,
        }
        assert.are.same(product, {
            type = "item",
            name = "wood",
            amount = 3,
        })
    end)

    it("-- valid long fluid + probability", function()
        local product = Product.make{
            type = "fluid",
            name = "water",
            amount = 5,
            probability = 0.25,
        }
        assert.are.same(product, {
            type = "fluid",
            name = "water",
            amount = 5,
            probability = 0.25,
        })
    end)

    it("-- valid long item + amount_min & max", function()
        local product = Product.make{
            type = "fluid",
            name = "water",
            amount_min = 5,
            amount_max = 8,
        }
        assert.are.same(product, {
            type = "fluid",
            name = "water",
            amount_min = 5,
            amount_max = 8,
        })
    end)

    it("-- mixed format", function()
        assert.error(function()
            Product.make{
                [1] = "wood",
                amount = 5,
            }
        end)
    end)

    it("-- wrong type", function()
        assert.error(function()
            Product.make{
                type = "gas",
                name = "methane",
                amount = 1,
            }
        end)
    end)

    it("-- no name", function()
        assert.error(function()
            Product.make{
                type = "gas",
                amount = 5,
            }
        end)
    end)

    it("-- no amount", function()
        assert.error(function()
            Product.make{
                type = "fluid",
                name = "water",
            }
        end)
    end)

    it("-- wrong probability", function()
        assert.error(function()
            Product.make{
                type = "fluid",
                name = "water",
                amount = 2,
                probability = 1.5,
            }
        end)
    end)

    it("-- only amount_min", function()
        assert.error(function()
            Product.make{
                type = "item",
                name = "pistol",
                amount_min = 4,
            }
        end)
    end)

    it("-- amount_min > amount_max", function()
        assert.error(function()
            Product.make{
                type = "item",
                name = "pistol",
                amount_min = 4,
                amount_max = 2,
            }
        end)
    end)
end)
