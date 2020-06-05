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
local ForceRecipe = require("lua/model/ForceRecipe")

local cLogger = ClassLogger.new{className = "Force"}

-- Wrapper of Factorio's LuaForce class.
--
-- RO Fields:
-- * prototypes: PrototypesDatabase that this object should use to get intermediates and transforms.
-- * rawForce: LuaForce object wrapped by this object.
--
local Force = ErrorOnInvalidRead.new{
    -- Creates a new Force object.
    --
    -- Args:
    -- * object: Table to turn into a Force object (required fields: prototypes, rawForce).
    --
    -- Returns: The argument turned into a Force object.
    --
    new = function(object)
        local prototypes = cLogger:assertField(object, "prototypes")
        local rawForce = cLogger:assertField(object, "rawForce")
        object.recipes = ErrorOnInvalidRead.new()
        for recipeName,recipe in pairs(rawForce.recipes) do
            object.recipes[recipeName] = ForceRecipe.make(recipe, prototypes.transforms)
        end
        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Restores the metatable of an Force object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)

        ErrorOnInvalidRead.setmetatable(object.recipes)
        for _,forceRecipe in pairs(object.recipes) do
            ForceRecipe.setmetatable(forceRecipe)
        end
    end,
}

return Force
