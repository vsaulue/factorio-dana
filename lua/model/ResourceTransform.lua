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

local AbstractTransform = require("lua/model/AbstractTransform")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local Metatable

-- Transform associated to a resource prototype.
--
-- Inherits from AbstractTransform.
--
-- RO Field:
-- * rawResource: Resource prototype wrapped by this transform.
--
local ResourceTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of a ResourceTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractTransform.setmetatable(object, Metatable)
    end,

    -- Creates a new ResourceTransforms if the resource entity prototype is mineable.
    --
    -- Args:
    -- * resourceEntityPrototype: Factorio prototype of a resource.
    -- * intermediatesDatabase: Database containing the Intermediate object to use for this transform.
    --
    -- Returns: The new ResourceTransform object if the entity is mineable. Nil otherwise.
    --
    tryMake = function(resourceEntityPrototype, intermediatesDatabase)
        local result = nil
        local mineable_props = resourceEntityPrototype.mineable_properties
        local rawProducts = mineable_props.products
        if mineable_props.minable and rawProducts and rawProducts[1] then
            result = AbstractTransform.new({
                type = "resource",
                rawResource = resourceEntityPrototype,
            }, Metatable)

            local fluidName = mineable_props.required_fluid
            if fluidName then
                local fluid = intermediatesDatabase.fluid[fluidName]
                result:addIngredient(fluid, mineable_props.fluid_amount)
            end

            result:addRawProductArray(intermediatesDatabase, rawProducts)
        end
        return result
    end,

    -- LocalisedString representing the type.
    TypeLocalisedStr = AbstractTransform.makeTypeLocalisedStr("resourceType"),
}

-- Metatable of the ResourceTransform class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform:generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("entity", self.rawResource)
        end,

        -- Implements AbstractTransform:getTypeStr().
        getShortName = function(self)
            return self.rawResource.localised_name
        end,

        -- Implements AbstractTransform:getTypeStr().
        getTypeStr = function(self)
            return ResourceTransform.TypeLocalisedStr
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractTransform.Metatable.__index})

return ResourceTransform
