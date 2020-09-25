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
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local ProductAmount = require("lua/model/ProductAmount")

local cLogger = ClassLogger.new{className = "BoilerTransform"}

local Metatable

-- Transform associated to a boiler.
--
-- Example: The vanilla boiler turns 'water' into 'steam' (which are 2 different fluids in the game).
--
-- Not all boilers will be mapped into a transform (some boilers just heat the fluid).
--
-- Inherits from AbstractTransform.
--
-- RO Fields:
-- * rawBoiler: Prototype of the boiler doing this transform.
--
local BoilerTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of a BoilerTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractTransform.setmetatable(object, Metatable)
    end,

    -- Creates a new BoilerTransforms if the given boiler prototype actually performs a transformation.
    --
    -- Args:
    -- * boilerPrototype: Factorio prototype of a boiler.
    -- * intermediatesDatabase: Database containing the Intermediate object to use for this transform.
    --
    -- Returns: The new BoilerTransform object if the boiler does a transformation. Nil otherwise.
    --
    tryMake = function(boilerPrototype, intermediatesDatabase)
        local result = nil
        local inputs = ErrorOnInvalidRead.new()
        local inputCount = 0
        local outputs = ErrorOnInvalidRead.new()
        local outputCount = 0
        for _,fluidbox in pairs(boilerPrototype.fluidbox_prototypes) do
            if fluidbox.filter then
                local fluid = intermediatesDatabase.fluid[fluidbox.filter.name]
                local boxType = fluidbox.production_type
                if boxType == "output" then
                    outputs[fluid] = true
                    outputCount = outputCount + 1
                elseif boxType == "input-output" or boxType == "input" then
                    inputs[fluid] = true
                    inputCount = inputCount + 1
                end
            end
        end
        if inputCount >= 1 and outputCount >= 1 then
            if inputCount == 1 and outputCount == 1 then
                result = AbstractTransform.new({
                    type = "boiler",
                    rawBoiler = boilerPrototype,
                }, Metatable)
                result:addIngredient(next(inputs), 1)
                result:addProduct(next(outputs), ProductAmount.makeConstant(1))
            else
                cLogger:warn("Boiler prototype '" .. boilerPrototype.name .. "' ignored (multiple inputs or outputs).")
            end
        end
        return result
    end,

    -- LocalisedString representing the type.
    TypeLocalisedStr = AbstractTransform.makeTypeLocalisedStr("boilerType"),
}

-- Metatable of the BoilerTransform class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform:generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("entity", self.rawBoiler)
        end,

        -- Implements AbstractTransform:getTypeStr().
        getShortName = function(self)
            return self.rawBoiler.localised_name
        end,

        -- Implements AbstractTransform:getTypeStr().
        getTypeStr = function(self)
            return BoilerTransform.TypeLocalisedStr
        end,
    },
}
setmetatable(Metatable.__index, {__index = AbstractTransform.Metatable.__index})

return BoilerTransform
