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

local cLogger = ClassLogger.new{className = "Intermediate"}

local TypeToLocalisedStr

-- Class representing intermediates between crafting steps.
--
-- RO Fields:
-- * localisedName: A localised string of the form "[type] name".
-- * rawPrototype: Wrapped Item/Fluid prototype from Factorio.
-- * spritePath: Sprite path of the underlying prototype.
-- * type: string designing the type of prototype (either "item" or "fluid").
--
local Intermediate = ErrorOnInvalidRead.new{
    -- Creates a new Intermediate object.
    --
    -- Args:
    -- * object: Table to turn into an Intermediate object (required field: rawPrototype).
    --
    -- Returns: the argument turned into an Intermediate.
    --
    new = function(object)
        local rawPrototype = cLogger:assertField(object, "rawPrototype")
        local type = cLogger:assertField(object, "type")
        ErrorOnInvalidRead.setmetatable(object)
        object.localisedName = {"dana.model.intermediate.name", TypeToLocalisedStr[type], rawPrototype.localised_name}
        object.spritePath = type .. "/" .. rawPrototype.name
        return object
    end,

    -- Restores the metatable of a Intermediate object, and all its owned objects.
    setmetatable = ErrorOnInvalidRead.setmetatable,

    -- Map[type] -> localised string.
    TypeToLocalisedStr = ErrorOnInvalidRead.new{
        fluid = {"dana.model.intermediate.fluidType"},
        item = {"dana.model.intermediate.itemType"},
    },
}

TypeToLocalisedStr = Intermediate.TypeToLocalisedStr

return Intermediate
