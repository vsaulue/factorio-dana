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

local Ingredient = require("lua/testing/mocks/Ingredient")

describe("Ingredient.make()", function()
    it("-- valid short format", function()
        local ingredient = Ingredient.make{"wood", 5}
        assert.are.same(ingredient, {
            type = "item",
            name = "wood",
            amount = 5,
        })
    end)

    it("-- valid long item", function()
        local ingredient = Ingredient.make{
            type = "item",
            name = "pistol",
            amount = 7,
        }
        assert.are.same(ingredient, {
            type = "item",
            name = "pistol",
            amount = 7,
        })
    end)

    it("-- valid long fluid", function()
        local ingredient = Ingredient.make{
            type = "fluid",
            name = "water",
            amount = 1,
        }
        assert.are.same(ingredient, {
            type = "fluid",
            name = "water",
            amount = 1,
        })
    end)

    it("-- mixed", function()
        assert.error(function()
            Ingredient.make{
                type = "item",
                [1] = "wood",
                amount = 2,
            }
        end)
    end)

    it("-- no amount", function()
        assert.error(function()
            Ingredient.make{
                type = "fluid",
                name = "water",
            }
        end)
    end)

    it("-- no name", function()
        assert.error(function()
            Ingredient.make{
                type = "fluid",
                amount = 5,
            }
        end)
    end)

    it("-- unknown type", function()
        assert.error(function()
            Ingredient.make{
                type = "gas",
                name = "steam",
                amount = 1,
            }
        end)
    end)
end)
