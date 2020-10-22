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
local LuaEntityPrototype = require("lua/testing/mocks/LuaEntityPrototype")
local LuaFluidPrototype = require("lua/testing/mocks/LuaFluidPrototype")
local LuaItemPrototype = require("lua/testing/mocks/LuaItemPrototype")
local LuaRecipePrototype = require("lua/testing/mocks/LuaRecipePrototype")
local MockGetters = require("lua/testing/mocks/MockGetters")

local cLogger
local getIngredientOrProduct
local Metatable
local parse
local TypeToIndex

-- Mock implementation of Factorio's LuaGameScript.
--
-- See https://lua-api.factorio.com/1.0.0/LuaGameScript.html
--
-- Inherits from CommonMockObject.
--
-- Implemented fields & methods:
-- * entity_prototypes (resource only).
-- * fluid_prototypes
-- * item_prototypes
-- * recipe_prototypes
-- + AbstractPrototype.
--
local LuaGameScript = {
    -- Creates a new LuaGameScript object.
    --
    -- Args:
    -- * rawData: table. Construction info from the data phase.
    --
    -- Returns: LuaGameScript. The new object.
    make = function(rawData)
        local selfData = {
            entity_prototypes = {},
            fluid_prototypes = {},
            item_prototypes = {},
            recipe_prototypes = {},
        }
        parse(selfData.fluid_prototypes, rawData.fluid, LuaFluidPrototype.make)
        parse(selfData.item_prototypes, rawData.item, LuaItemPrototype.make)

        parse(selfData.recipe_prototypes, rawData.recipe, function(rawPrototypeData)
            local result = LuaRecipePrototype.make(rawPrototypeData)
            for index,ingredientInfo in ipairs(result.ingredients) do
                if not getIngredientOrProduct(selfData, ingredientInfo) then
                    local msg = "Undeclared ingredient of recipe '" .. result.name .. "': " .. ingredientInfo.type
                             .. " '" .. ingredientInfo.name .. "'."
                    cLogger:error(msg)
                end
            end
            for index,productInfo in ipairs(result.products) do
                if not getIngredientOrProduct(selfData, productInfo) then
                    local msg = "Undeclared product of recipe '" .. result.name .. "': " .. productInfo.type
                             .. " '" .. productInfo.name .. "'."
                    cLogger:error(msg)
                end
            end
            return result
        end)

        parse(selfData.entity_prototypes, rawData.resource, function(rawPrototypeData)
            local result = LuaEntityPrototype.make(rawPrototypeData)
            local mineProps = result.mineable_properties
            if mineProps.products then
                for index,productInfo in ipairs(mineProps.products) do
                    if not getIngredientOrProduct(selfData, productInfo) then
                        local msg = "Undeclared mining product of entity '" .. result.name .. "': " .. productInfo.type
                                 .. " '" .. productInfo.name .. "'."
                        cLogger:error(msg)
                    end
                end
            end
            local requiredFluid = mineProps.required_fluid
            if requiredFluid then
                if not selfData.fluid_prototypes[requiredFluid] then
                    local msg = "Undeclared mining fluid of entity '" .. result.name .. "': " .. requiredFluid .. "."
                    cLogger:error(msg)
                end
            end
            return result
        end)

        return CommonMockObject.make(selfData, Metatable)
    end,
}

-- Metatable of the LuaGameScript class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaGameScript",

    getters = {
        entity_prototypes = MockGetters.validReadOnly("entity_prototypes"),
        fluid_prototypes = MockGetters.validReadOnly("fluid_prototypes"),
        item_prototypes = MockGetters.validReadOnly("item_prototypes"),
        recipe_prototypes = MockGetters.validReadOnly("recipe_prototypes"),
    },
}

cLogger = Metatable.cLogger

-- Gets the prototype of an item/fluid associated to a Ingredient/Product object.
--
-- Args:
-- * selfData: table. Internal data table of the LuaGameScript containing the prototypes.
-- * ingredientOrProduct: Ingredient or Product. Item/fluid to look for.
--
-- Returns: The corresponding LuaItemPrototype or LuaFluidPrototype. Nil if not found.
--
getIngredientOrProduct = function(selfData, ingredientOrProduct)
    local result = nil
    local mapIndex = TypeToIndex[ingredientOrProduct.type]
    if mapIndex then
        result = selfData[mapIndex][ingredientOrProduct.name]
    end
    return result
end

-- Generates prototypes from a specific map.
--
-- Args:
-- * outputTable[string]: AbstractPrototype. Map where the generated prototypes will be stored
--       (indexed by prototype name).
-- * inputTable[string]: table. Construction info of each prototype from the data phase
--       (indexed by prototype name).
-- * prototypeMaker: function(table) -> AbstractPrototype. Function to generate the prototypes.
--
parse = function(outputTable, inputTable, prototypeMaker)
    if inputTable then
        for name,rawPrototypeData in pairs(inputTable) do
            local newPrototype = prototypeMaker(rawPrototypeData)
            cLogger:assert(name == newPrototype.name, "Prototype at index '" .. tostring(name) .. "' has a mismatching name")
            cLogger:assert(not outputTable[name], "Duplicate prototype name: " .. tostring(name))
            outputTable[name] = newPrototype
        end
    end
end

-- Map[string]: string. Map of LuaGameScript field indices, indexed by their intermediate type.
TypeToIndex = {
    fluid = "fluid_prototypes",
    item = "item_prototypes",
}

return LuaGameScript
