-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

-- Wrapper of Factorio's LuaTechnology object.
--
-- RO Fields:
-- * rawTechnology: Wrapped LuaTechnology object.
-- * researchTransform: ResearchTransform object associated to this technology.
--
local ForceTechnology = ErrorOnInvalidRead.new{
    -- Makes a ForceTechnology from a LuaTechnology object.
    --
    -- Args:
    -- * rawTechnology: LuaTechnology object to wrap.
    -- * transforms: TransformsDatabase to use to get the related ResearchTransform object.
    --
    make = function(rawTechnology, transforms)
        local transform = transforms.research[rawTechnology.name]
        return ErrorOnInvalidRead.new{
            rawTechnology = rawTechnology,
            researchTransform = transform,
        }
    end,

    -- Restores the metatable of an ForceTechnology object, and all its owned objects.
    setmetatable = ErrorOnInvalidRead.setmetatable,
}

return ForceTechnology
