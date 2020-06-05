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

-- Transform associated to a resource prototype.
--
-- RO Field: same as AbstractTransform.
--
local ResourceTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of a ResourceTransform object, and all its owned objects.
    setmetatable = AbstractTransform.setmetatable,

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
        if mineable_props.minable then
            local products = ErrorOnInvalidRead.new()
            for _,product in pairs(mineable_props.products) do
                local intermediate = intermediatesDatabase:getIngredientOrProduct(product)
                products[intermediate] = true
            end

            local ingredients = ErrorOnInvalidRead.new()
            local fluidName = mineable_props.required_fluid
            if fluidName then
                local intermediate = intermediatesDatabase.fluid[fluidName]
                ingredients[intermediate] = true
            end

            result = AbstractTransform.new{
                type = "entity",
                rawPrototype = resourceEntityPrototype,
                ingredients = ingredients,
                products = products,
            }
        end
        return result
    end,
}

return ResourceTransform