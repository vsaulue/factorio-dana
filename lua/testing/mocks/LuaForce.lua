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

local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local LuaRecipe = require("lua/testing/mocks/LuaRecipe")
local MockGetters = require("lua/testing/mocks/MockGetters")

local Metatable

-- Mock implementation of Factorio's LuaForce.
--
-- See https://lua-api.factorio.com/1.0.0/LuaForce.html
--
-- Implemented fields & methods:
-- * recipes
-- + CommonMockObject
--
local LuaForce = {
    -- Creates a new LuaForce object.
    --
    -- Args:
    -- * recipePrototypes[string]: LuaRecipePrototype. Map of recipes to wrap.
    --
    -- Returns: The new LuaForce object.
    --
    make = function(recipePrototypes)
        local recipes = {}
        local result = CommonMockObject.make({
            recipes = recipes,
        }, Metatable)
        for name,prototype in pairs(recipePrototypes) do
            recipes[name] = LuaRecipe.make{
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
    },
}

return LuaForce
