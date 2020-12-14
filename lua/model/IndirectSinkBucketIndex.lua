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

local cLogger = ClassLogger.new{className = "IndirectSinkBucketIndex"}

local new

-- Class representing an index of an "indirect sink" bucket.
--
-- In order to detect indirect sink recipes, transforms are grouped into "buckets".
-- Two transforms are currently in the same bucket if:
-- * they give the same unique products & amounts.
-- * they have a unique ingredient (the ingredient may be different between transforms).
-- * they have the same ingredient amount.
--
-- RO Fields:
-- * iAmount: int. Amount of ingredient consumed by the transforms of this bucket.
-- * products: AbstractTransform.products. Shared products of the transforms in this bucket.
--
local IndirectSinkBucketIndex = ErrorOnInvalidRead.new{
    -- Creates a copy of a IndirectSinkBucketIndex.
    --
    -- Args:
    -- * data: table. Same fields as IndirectSinkBucketIndex.
    --
    -- Returns: IndirectSinkBucketIndex.
    --
    copy = function(data)
        return new{
            iAmount = data.iAmount,
            products = data.products,
        }
    end,

    -- Tests the equality between IndirectSinkBucketIndex objects.
    --
    -- Args:
    -- * cached: IndirectSinkBucketIndex. Proper object with metatable.
    -- * data: table. Same fields as the built type. However, it might not have its metatable.
    --
    -- Returns: boolean. True if equals, false if different.
    --
    equals = function(self, data)
        return self.iAmount == data.iAmount and self.products == data.products
    end,

    -- Creates a new IndirectSinkBucketIndex object.
    --
    -- Args:
    -- * object: table. Required fields: iAmount, products.
    --
    -- Returns: IndirectSinkBucketIndex. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertField(object, "iAmount")
        cLogger:assertField(object, "products")
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,
}

new = IndirectSinkBucketIndex.new

return IndirectSinkBucketIndex
