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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ProductInfo = require("lua/model/ProductInfo")

local cLogger = ClassLogger.new{className = "AbstractTransform"}

-- Class holding the data of a transformation.
--
-- A transform is something (recipe, mining, electricity/heat generation...) that turns a given
-- set of Intermediates into another set of Intermediates.
--
-- RO Fields:
-- * ingredients: Set of Intermediates consumed by this transform.
-- * localisedName: A localised string of the form "[type] name".
-- * products[intermediate] -> ProductInfo: Map of products.
-- * spritePath: Sprite path of the underlying prototype.
-- * type: String representing the type of the transform.
--
-- Methods: see the commented Metatable below.
--
local AbstractTransform = ErrorOnInvalidRead.new{
    -- Generates a SpritePath for a prototype.
    --
    -- Args:
    -- * spriteType: String representing the type of sprite.
    -- * prototype: Prototype containing the sprite.
    --
    -- Returns: The SpritePath of the prototype.
    --
    makeSpritePath = function(spriteType, prototype)
        return spriteType .. "/" .. prototype.name
    end,

    -- Generates a LocalisedString for a transform type.
    --
    -- Args:
    -- * suffix: Suffix of the locale path.
    --
    -- Returns: A LocalisedString for the transform.
    --
    makeTypeLocalisedStr = function(suffix)
        return {"dana.model.transform." .. suffix}
    end,

    -- Metatable of the AbstractTransform class.
    Metatable = {
        __index = {
            -- Adds a product to this transform.
            --
            -- Args:
            -- * self: AbstractTransform object.
            -- * intermediate: Product to add.
            -- * productInfo: Associated ProductInfo object.
            --
            addProduct = function(self, intermediate, productInfo)
                if productInfo.amountMax > 0 and productInfo.probability > 0 then
                    cLogger:assert(not rawget(self.products, intermediate), "Duplicate product in transform.")
                    self.products[intermediate] = productInfo
                end
            end,

            -- Adds a product from an API's Product object.
            --
            -- Args:
            -- * self: AbstractTransform object.
            -- * intermediatesDb: IntermediatesDatabase used to find the Intermediate.
            -- * rawProduct: Product object from Factorio's API.
            --
            addRawProduct = function(self, intermediatesDb, rawProduct)
                local intermediate = intermediatesDb:getIngredientOrProduct(rawProduct)
                self:addProduct(intermediate, ProductInfo.makeFromRawProduct(rawProduct))
            end,

            -- Adds an array of Product from the API.
            --
            -- Args:
            -- * self: AbstractTransform object.
            -- * intermediatesDb: IntermediatesDatabase used to find the Intermediate.
            -- * rawProducts: Array of Product objects from Factorio's API.
            --
            addRawProductArray = function(self, intermediatesDb, rawProducts)
                for _,rawProduct in pairs(rawProducts) do
                    self:addRawProduct(intermediatesDb, rawProduct)
                end
            end,

            -- Generates a SpritePath representing this transform.
            --
            -- Args:
            -- * self: AbstractTransform object.
            --
            -- Returns: A SpritePath object (Factorio API).
            --
            generateSpritePath = nil, -- function(self) end

            -- Gets a LocalisedString corresponding to the wrapped prototype.
            --
            -- Args:
            -- * self: AbstractTransform object.
            --
            -- Returns: The LocalisedString of the name of the wrapped prototype.
            --
            getShortName = nil, -- function(self) end

            -- Gets a LocalisedString of the type of this transform.
            --
            -- Args:
            -- * self: AbstractTransform object.
            --
            -- Returns: The type as a LocalisedString.
            --
            getTypeStr = nil, -- function(self) end
        },
    },

    -- Creates a new AbstractTransform object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractTransform object.
    -- * metatable: Metatable to set.
    --
    new = function(object, metatable)
        setmetatable(object, metatable)
        cLogger:assertField(object, "ingredients")
        local type = cLogger:assertField(object, "type")
        object.products = ErrorOnInvalidRead.new()
        object.localisedName = {"dana.model.transform.name", object:getTypeStr(), object:getShortName()}
        object.spritePath = object:generateSpritePath()
        return object
    end,

    -- Restores the metatable of an AbstractTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    -- * metatable: Metatable to set.
    --
    setmetatable = function(object, metatable)
        setmetatable(object, metatable)
        ErrorOnInvalidRead.setmetatable(object.ingredients)

        ErrorOnInvalidRead.setmetatable(object.products)
        for _,product in pairs(object.products) do
            ProductInfo.setmetatable(product)
        end
    end,
}

return AbstractTransform
