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

local AbstractTransform = require("lua/model/AbstractTransform")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ProductAmount = require("lua/model/ProductAmount")

local Metatable

-- Transform associated to fuel items generating a byproduct when used.
--
-- Example: 'Uranium fuel cell' -> 'Used-up uranium fuel cell'.
--
-- Inherits from AbstractTransform.
--
-- RO Fields:
-- * inputItem: Item prototype that is the input of this transform.
--
local FuelTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of a FuelTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractTransform.setmetatable(object, Metatable)
    end,

    -- Creates a new FuelTransform if the item generates a byproduct when used as fuel.
    --
    -- Args:
    -- * itemIntermediate: Factorio prototype of an item.
    -- * intermediatesDatabase: Database containing the Intermediate objects to use for this transform.
    --
    -- Returns: The new FuelTransform if the fuel item generates a byproduct at usage. Nil otherwise.
    --
    tryMake = function(itemIntermediate, intermediatesDatabase)
        local result = nil
        local burnt_result = itemIntermediate.rawPrototype.burnt_result
        if burnt_result then
            local product = intermediatesDatabase.item[burnt_result.name]
            result = AbstractTransform.new({
                type = "fuel",
                inputItem = itemIntermediate,
            }, Metatable)
            result:addIngredient(itemIntermediate, 1)
            result:addProduct(product, ProductAmount.makeConstant(1))
        end
        return result
    end,

        -- LocalisedString representing the type.
    TypeLocalisedStr = AbstractTransform.makeTypeLocalisedStr("fuelType"),
}

-- Metatable of the FuelTransform class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform;generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("item", self.inputItem.rawPrototype.burnt_result)
        end,

        -- Implements AbstractTransform:getTypeStr().
        getShortName = function(self)
            return self.inputItem.rawPrototype.localised_name
        end,

        -- Implements AbstractTransform:getTypeStr().
        getTypeStr = function(self)
            return FuelTransform.TypeLocalisedStr
        end,
    }
}
setmetatable(Metatable.__index, {__index = AbstractTransform.Metatable.__index})

return FuelTransform
