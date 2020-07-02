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

-- Transform associated to an offshore pump.
--
-- RO Fields: same as AbstractTransform.
--
local OffshorePumpTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of an OffshorePumpTransform object, and all its owned objects.
    setmetatable = AbstractTransform.setmetatable,

    -- Creates a new OffshorePumpTransform from an offshore-pump prototype.
    --
    -- Args:
    -- * offshorePumpPrototype: Factorio prototype of an offshore pump.
    -- * intermediatesDatabase: Database containing the Intermediate object to use for this transform.
    --
    -- Returns: The new OffshorePumpTransform object.
    --
    make = function(offshorePumpPrototype, intermediatesDatabase)
        local fluid = intermediatesDatabase.fluid[offshorePumpPrototype.fluid.name]
        return AbstractTransform.new{
            ingredients = ErrorOnInvalidRead.new(),
            products = ErrorOnInvalidRead.new{
                [fluid] = true,
            },
            rawPrototype = offshorePumpPrototype,
            type = "offshore-pump",
        }
    end,
}

return OffshorePumpTransform
