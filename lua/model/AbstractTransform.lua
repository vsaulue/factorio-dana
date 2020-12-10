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
local ProductAmount = require("lua/model/ProductAmount")
local ProductData = require("lua/model/ProductData")
local Set = require("lua/containers/Set")

local cLogger = ClassLogger.new{className = "AbstractTransform"}

-- Class holding the data of a transformation.
--
-- A transform is something (recipe, mining, electricity/heat generation...) that turns a given
-- set of Intermediates into another set of Intermediates.
--
-- RO Fields:
-- * ingredients[intermediate] -> int. Pairs of ingredients & quantities.
-- * localisedName: A localised string of the form "[type] name".
-- * products[intermediate] -> ProductData: Map of products.
-- * spritePath: Sprite path of the underlying prototype.
-- * type: String representing the type of the transform.
--
-- Methods: see the commented Metatable below.
--
local AbstractTransform = ErrorOnInvalidRead.new{
    -- Creates a new AbstractTransform object.
    --
    -- Args:
    -- * transformMaker: TransformMaker. Factory containing the transform to build.
    -- * metatable: table. Metatable to set.
    --
    -- Returns: AbstractTransform. The transform from the `transformMaker` argument.
    --
    make = function(transformMaker, metatable)
        local result = transformMaker:finaliseTransform()
        setmetatable(result, metatable)
        ErrorOnInvalidRead.setmetatable(result.ingredients)
        ErrorOnInvalidRead.setmetatable(result.products)
        cLogger:assertField(result, "type")
        result.localisedName = {"dana.model.transform.name", result:getTypeStr(), result:getShortName()}
        result.spritePath = result:generateSpritePath()
        return result
    end,

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
            -- Tests if two transforms forms a non-positive cycle.
            --
            -- Transform A forms a cycle with transform B if:
            -- * A.ingredients == B.products, and are not empty.
            -- * B.products == A.ingredients, and are not empty.
            --
            -- The loop is non-positive only if it can't be used to duplicate intermediates
            -- (ignoring productivity modules).
            --
            -- Args:
            -- * self: AbstractTransform object.
            -- * other: The other AbstractTransform object.
            --
            -- Returns: True if the two transforms forms a non-positive cycle.
            --
            isNonPositiveCycleWith = function(self, other)
                local result = false
                local products = self.products
                local oIngredients = other.ingredients
                if next(products) and Set.areEquals(products, oIngredients) then
                    local ingredients = self.ingredients
                    local oProducts = other.products
                    if next(ingredients) and Set.areEquals(ingredients, oProducts) then
                        local ratio = math.huge
                        for intermediate,productInfo in pairs(products) do
                            ratio = math.min(ratio, oIngredients[intermediate] / productInfo:getAvg())
                        end

                        result = true
                        for intermediate,productInfo in pairs(oProducts) do
                            result = result and (ratio * ingredients[intermediate] > 0.999 * productInfo:getAvg())
                        end
                    end
                end
                return result
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
        local type = cLogger:assertField(object, "type")
        object.ingredients = ErrorOnInvalidRead.new()
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
        for _,productData in pairs(object.products) do
            ProductData.setmetatable(productData)
        end
    end,
}

return AbstractTransform
