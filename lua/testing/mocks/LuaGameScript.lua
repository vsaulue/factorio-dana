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

local AbstractPrototype = require("lua/testing/mocks/AbstractPrototype")
local CommonMockObject = require("lua/testing/mocks/CommonMockObject")
local IndexGenerator = require("lua/testing/mocks/IndexGenerator")
local LuaEntityPrototype = require("lua/testing/mocks/LuaEntityPrototype")
local LuaFluidPrototype = require("lua/testing/mocks/LuaFluidPrototype")
local LuaForce = require("lua/testing/mocks/LuaForce")
local LuaItemPrototype = require("lua/testing/mocks/LuaItemPrototype")
local LuaPlayer = require("lua/testing/mocks/LuaPlayer")
local LuaRecipePrototype = require("lua/testing/mocks/LuaRecipePrototype")
local LuaSurface = require("lua/testing/mocks/LuaSurface")
local MockGetters = require("lua/testing/mocks/MockGetters")
local MockObject = require("lua/testing/mocks/MockObject")

local cLogger
local getIngredientOrProduct
local DefaultForceNames
local doCreateForce
local linkerError
local Linkers
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
-- * create_force
-- * entity_prototypes (boiler, offshore-pump, resource).
-- * fluid_prototypes
-- * forces
-- * item_prototypes
-- * recipe_prototypes
-- * surfaces
-- + AbstractPrototype.
--
-- Private fields:
-- * surfaceIndexGenerator: IndexGenerator. Index generator for surfaces.
--
local LuaGameScript = {
    -- Adds a new player to a LuaGameScript.
    --
    -- Args:
    -- * self: LuaGameScript.
    -- * cArgs: table. May contain the following fields:
    -- **  forceName: string. Name of the force of this player.
    --
    -- Returns: LuaPlayer. The new player.
    --
    createPlayer = function(self, cArgs)
        local data = MockObject.getData(self)
        local force = data.forces[cArgs.forceName]
        cLogger:assert(force, "Invalid force name: " .. tostring(cArgs.forceName))
        local result = LuaPlayer.make{
            force = force,
        }
        data.players[result.index] = result
        return result
    end,

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
            forces = {},
            item_prototypes = {},
            players = {},
            recipe_prototypes = {},
            surfaceIndexGenerator = IndexGenerator.new(),
            surfaces = {},
        }
        parse(selfData.fluid_prototypes, rawData.fluid, LuaFluidPrototype.make)
        for pType in pairs(AbstractPrototype.ItemTypes) do
            parse(selfData.item_prototypes, rawData[pType], LuaItemPrototype.make)
        end
        parse(selfData.recipe_prototypes, rawData.recipe, LuaRecipePrototype.make)
        parse(selfData.entity_prototypes, rawData.boiler, LuaEntityPrototype.make)
        parse(selfData.entity_prototypes, rawData.resource, LuaEntityPrototype.make)
        parse(selfData.entity_prototypes, rawData["offshore-pump"], LuaEntityPrototype.make)

        for index,linker in pairs(Linkers) do
            for _,prototype in pairs(selfData[index]) do
                linker(selfData, prototype)
            end
        end
        for forceName in pairs(DefaultForceNames) do
            doCreateForce(selfData, forceName)
        end

        return CommonMockObject.make(selfData, Metatable)
    end,
}

-- Metatable of the LuaGameScript class.
Metatable = CommonMockObject.Metatable:makeSubclass{
    className = "LuaGameScript",

    getters = {
        create_force = function(self)
            return function(name)
                local data = MockObject.getData(self)
                return doCreateForce(data, name)
            end
        end,

        create_surface = function(self)
            return function(name, settings)
                local data = MockObject.getData(self)
                return doCreateSurface(data, name, settings)
            end
        end,

        entity_prototypes = MockGetters.validReadOnly("entity_prototypes"),
        fluid_prototypes = MockGetters.validReadOnly("fluid_prototypes"),
        forces = MockGetters.validReadOnly("forces"),
        item_prototypes = MockGetters.validReadOnly("item_prototypes"),
        players = MockGetters.validReadOnly("players"),
        recipe_prototypes = MockGetters.validReadOnly("recipe_prototypes"),
        surfaces = MockGetters.validReadOnly("surfaces"),
    },
}

cLogger = Metatable.cLogger

-- Set<string>. Names of the default LuaForce of a game.
DefaultForceNames = {
    enemy = true,
    neutral = true,
    player = true,
}

-- Creates a new Force in a game.
--
-- Args:
-- * selfData: table. Internal data of the LuaGameScript.
-- * forceName: string. Name of the new force.
--
-- Returns: The new LuaForce.
--
doCreateForce = function(selfData, forceName)
    local forces = selfData.forces
    cLogger:assert(not forces[forceName], "Duplicate force index: " .. forceName)
    local result = LuaForce.make(selfData.recipe_prototypes)
    forces[forceName] = result
    return result
end

-- Creates a new surface in a game.
--
-- Args:
-- * selfData: table. Internal data of the LuaGameScript.
-- * name: string. Name of the new surface.
-- * settings: table. Parameters for the creation of the surface.
--
-- Returns: LuaSurface.
--
doCreateSurface = function(selfData, name, settings)
    local surfaces = selfData.surfaces
    cLogger:assert(not surfaces[name], "Duplicate surface index: " .. name)
    local result = LuaSurface.make{
        index = selfData.surfaceIndexGenerator:newIndex(),
        name = name,
    }
    surfaces[name] = result
    return result
end

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

-- Generates an error for invalid cross-prototype references.
--
-- Args:
-- * basePrototype: AbstractPrototype. Prototype containing the reference.
-- * propertyName: string. Name of the field in `basePrototype` containing the cross-reference.
-- * searchedType: string. Type of the referenced prototype.
-- * searchedName: string. Name of the referenced prototype.
--
linkerError = function(basePrototype, propertyName, searchedType, searchedName)
    local msg = "In " .. basePrototype.type .. " '" .. basePrototype.name .. "': Undefined " .. propertyName
             .. " (" .. searchedType .. " '" .. searchedName .. "')"
    cLogger:error(msg)
end

-- Map[string] -> function(LuaGameScript.Data, AbstractPrototype).
--
-- Linkers are functions that sets the cross-prototype references in each prototypes.
--
-- This map gives the linker function to run on each prototype collection in LuaGameScript.
Linkers = {
    entity_prototypes = function(selfData, entityPrototype)
        local entityData = MockObject.getData(entityPrototype)
        -- mineable_properties
        local mineProps = entityPrototype.mineable_properties
        if mineProps.products then
            for index,productInfo in ipairs(mineProps.products) do
                if not getIngredientOrProduct(selfData, productInfo) then
                    linkerError(entityPrototype, "minable products", productInfo.type, productInfo.name)
                end
            end
        end
        local requiredFluid = mineProps.required_fluid
        if requiredFluid then
            if not selfData.fluid_prototypes[requiredFluid] then
                linkerError(entityPrototype, "mining fluid", "fluid", requiredFluid)
            end
        end

        -- others
        local fluid = entityData.fluid
        if fluid then
            local fluidPrototype = selfData.fluid_prototypes[fluid]
            if not fluidPrototype then
                linkerError(entityPrototype, "fluid", "fluid", fluid)
            end
            entityData.fluid = fluidPrototype
        end

        for _,fluidbox in ipairs(entityData.fluidbox_prototypes) do
            local fluidboxData = MockObject.getData(fluidbox)
            local filter = fluidboxData.filter
            if filter then
                local fluidPrototype = selfData.fluid_prototypes[filter]
                if not fluidPrototype then
                    linkerError(entityPrototype, "fluidbox_prototypes", "fluid", filter)
                end
                fluidboxData.filter = fluidPrototype
            end
        end
    end,

    item_prototypes = function(selfData, itemPrototype)
        local itemData = MockObject.getData(itemPrototype)
        local burntName = itemData.burnt_result
        if burntName then
            local burntPrototype = selfData.item_prototypes[burntName]
            if not burntPrototype then
                linkerError(itemPrototype, "burnt_result", "item", burntName)
            end
            itemData.burnt_result = burntPrototype
        end
    end,

    recipe_prototypes = function(selfData, recipePrototype)
        for index,ingredientInfo in ipairs(recipePrototype.ingredients) do
            if not getIngredientOrProduct(selfData, ingredientInfo) then
                linkerError(recipePrototype, "ingredient", ingredientInfo.type, ingredientInfo.name)
            end
        end
        for index,productInfo in ipairs(recipePrototype.products) do
            if not getIngredientOrProduct(selfData, productInfo) then
                linkerError(recipePrototype, "product", productInfo.type, productInfo.name)
            end
        end
    end,
}

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
