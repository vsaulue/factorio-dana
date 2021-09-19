-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local MetaUtils = require("lua/class/MetaUtils")

local Metatable

-- Transform associated to researching a new technology.
--
-- Inherits from AbstractTransform.
--
-- RO Fields:
-- * rawTechnology: LuaTechnologyPrototype. Factorio's technology unlocked by this research.
--
local ResearchTransform = ErrorOnInvalidRead.new{
    -- Restores the metatable of a ResearchTransform object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractTransform.setmetatable(object, Metatable)
    end,

    -- Creates a new ResearchTransform from a technology.
    --
    -- Args:
    -- * transformMaker: TransformMaker.
    -- * technologyPrototype: LuaTechnologyPrototype. Prototype of the technology unlocked by this research.
    --
    -- Returns: ResearchTransform.
    --
    make = function(transformMaker, technologyPrototype)
        transformMaker:newTransform{
            type = "research",
            rawTechnology = technologyPrototype,
        }
        for prerequisiteName in pairs(technologyPrototype.prerequisites) do
            transformMaker:addIngredient("technology", prerequisiteName, 1)
        end
        transformMaker:addConstantProduct("technology", technologyPrototype.name, 1)
        return AbstractTransform.make(transformMaker, Metatable)
    end,

        -- LocalisedString representing the type.
    TypeLocalisedStr = AbstractTransform.makeTypeLocalisedStr("researchType"),
}

-- Metatable of the ResearchTransform class.
Metatable = MetaUtils.derive(AbstractTransform.Metatable, {
    __index = ErrorOnInvalidRead.new{
        -- Implements AbstractTransform;generateSpritePath().
        generateSpritePath = function(self)
            return AbstractTransform.makeSpritePath("technology", self.rawTechnology)
        end,

        -- Implements AbstractTransform:getTypeStr().
        getShortName = function(self)
            return self.rawTechnology.localised_name
        end,

        -- Implements AbstractTransform:getTypeStr().
        getTypeStr = function(self)
            return ResearchTransform.TypeLocalisedStr
        end,
    }
})

return ResearchTransform
