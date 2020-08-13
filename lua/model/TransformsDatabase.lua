-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local BoilerTransform = require("lua/model/BoilerTransform")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local FuelTransform = require("lua/model/FuelTransform")
local OffshorePumpTransform = require("lua/model/OffshorePumpTransform")
local RecipeTransform = require("lua/model/RecipeTransform")
local ResourceTransform = require("lua/model/ResourceTransform")

local cLogger = ClassLogger.new{className = "TransformsDatabase"}

local tryAddTransform
local Metatable

-- Class to hold a set of transforms.
--
-- RO Fields:
-- * boiler[entityName]: Map of BoilerTransform, indexed by the boiler entity's name.
-- * fuel[itemName]: Map of FuelTransform, indexed by the fuel item's name.
-- * intermediates: IntermediatesDatabase holding all the Intermediates in the transforms.
-- * offshorePump[entityName]: Map of OffshorePumpTransform, indexed by the entity's name.
-- * recipe[recipeName]: Map of RecipeTransform, indexed by the recipe's name.
-- * resource[entityName]: Map of ResourceTransform, indexed by the resource's name.
--
local TransformsDatabase = ErrorOnInvalidRead.new{
    -- Creates a new TransformsDatabase object.
    --
    -- Args:
    -- * object: Table to turn into a TransformsDatabase object (required field: "intermediates").
    --
    -- Returns: The new TransformsDatabase object.
    --
    new = function(object)
        cLogger:assertField(object, "intermediates")
        object.boiler = ErrorOnInvalidRead.new()
        object.fuel = ErrorOnInvalidRead.new()
        object.offshorePump = ErrorOnInvalidRead.new()
        object.recipe = ErrorOnInvalidRead.new()
        object.resource = ErrorOnInvalidRead.new()
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a TransformsDatabase object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)

        ErrorOnInvalidRead.setmetatable(object.boiler)
        for _,boilerTransform in pairs(object.boiler) do
            BoilerTransform.setmetatable(boilerTransform)
        end

        ErrorOnInvalidRead.setmetatable(object.fuel)
        for _,fuelTransform in pairs(object.fuel) do
            FuelTransform.setmetatable(fuelTransform)
        end

        ErrorOnInvalidRead.setmetatable(object.offshorePump)
        for _,offshoreTransform in pairs(object.offshorePump) do
            OffshorePumpTransform.setmetatable(offshoreTransform)
        end

        ErrorOnInvalidRead.setmetatable(object.recipe)
        for _,recipeTransform in pairs(object.recipe) do
            RecipeTransform.setmetatable(recipeTransform)
        end

        ErrorOnInvalidRead.setmetatable(object.resource)
        for _,resourceTransform in pairs(object.resource) do
            ResourceTransform.setmetatable(resourceTransform)
        end
    end,
}

-- Metatable of the TransformsDatabase class
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Resets the content of the database.
        --
        -- Args:
        -- * self: TransformsDatabase object.
        -- * gameScript: LuaGameScript object holding the new prototypes.
        --
        rebuild = function(self, gameScript)
            self.boiler = ErrorOnInvalidRead.new()
            self.fuel = ErrorOnInvalidRead.new()
            self.offshorePump = ErrorOnInvalidRead.new()
            self.recipe = ErrorOnInvalidRead.new()
            self.resource = ErrorOnInvalidRead.new()

            for _,entity in pairs(gameScript.entity_prototypes) do
                local transform = nil
                if entity.type == "resource" then
                    transform = ResourceTransform.tryMake(entity, self.intermediates)
                elseif entity.type == "offshore-pump" then
                    transform = OffshorePumpTransform.make(entity, self.intermediates)
                elseif entity.type == "boiler" then
                    transform = BoilerTransform.tryMake(entity, self.intermediates)
                end
                tryAddTransform(self, entity.name, transform)
            end

            for _,rawRecipe in pairs(gameScript.recipe_prototypes) do
                tryAddTransform(self, rawRecipe.name, RecipeTransform.make(rawRecipe, self.intermediates))
            end

            for _,item in pairs(self.intermediates.item) do
                tryAddTransform(self, item.rawPrototype.name, FuelTransform.tryMake(item, self.intermediates))
            end
        end,
    }
}

-- Adds a transform to this database.
--
-- Args:
-- * self: TransformsDatabase object.
-- * name: Name of the transform to add.
-- * transform: AbstractTransform to add. If nil, this function does nothing.
--
tryAddTransform = function(self, name, transform)
    if transform then
        local map = self[transform.type]
        cLogger:assert(not rawget(map, name), "Duplicate transform index.")
        map[name] = transform
    end
end

return TransformsDatabase
