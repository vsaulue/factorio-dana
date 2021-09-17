-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local LuaRecipe = require("lua/testing/mocks/LuaRecipe")
local LuaTechnology = require("lua/testing/mocks/LuaTechnology")
local MockGetters = require("lua/testing/mocks/MockGetters")

local Metatable

-- Mock implementation of Factorio's LuaForce.
--
-- See https://lua-api.factorio.com/1.0.0/LuaForce.html
--
-- Implemented fields & methods:
-- * recipes
-- * technologies
-- + CommonMockObject
--
local LuaForce = {
    -- Creates a new LuaForce object.
    --
    -- Args:
    -- * recipePrototypes: Map<string, LuaRecipePrototype>. Map of recipes to wrap, indexed by their names.
    -- * technologyPrototypes: Map<string, LuaTechnologyPrototype>. Map of technologies to wrap, indexed by their names.
    --
    -- Returns: The new LuaForce object.
    --
    make = function(recipePrototypes, technologyPrototypes)
        local recipes = {}
        local technologies = {}
        local result = CommonMockObject.make({
            recipes = recipes,
            technologies = technologies,
        }, Metatable)
        for name,prototype in pairs(recipePrototypes) do
            recipes[name] = LuaRecipe.make{
                force = result,
                prototype = prototype,
            }
        end
        for name,prototype in pairs(technologyPrototypes) do
            technologies[name] = LuaTechnology.make{
                force = result,
                prototype = prototype,
            }
        end
        return result
    end,
}

-- Metatable of the LuaForce class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaForce",

    getters = {
        recipes = MockGetters.validReadOnly("recipes"),
        technologies = MockGetters.validReadOnly("technologies"),
    },
}

return LuaForce
