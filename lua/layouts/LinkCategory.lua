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

local cLogger = ClassLogger.new{className = "LinkCategory"}

local Instances
local new

-- Class representing a link category in layouts.
--
-- This class keeps a copy of each instanced object in a map for later retrieval.
-- Layouts should make only one object for each category, and reuse it.
--
-- RO Fields:
-- * index: Unique identifier for this object.
-- * localisedDescription: A one line localised string explaining what this kind of link represents.
--
local LinkCategory = ErrorOnInvalidRead.new{
    -- Makes a new LinkCategory object, and stores it in the static map.
    --
    -- Args:
    -- * object: Table to turn into a LinkCategory object (required fields: all.
    --
    -- Returns: The argument turned into a LinkCategory object.
    --
    make = function(object)
        local index = cLogger:assertField(object, "index")
        cLogger:assertField(object, "localisedDescription")

        cLogger:assert(not rawget(Instances, index), "Duplicate index: " .. tostring(index))
        Instances[index] = object

        ErrorOnInvalidRead.setmetatable(object)
        return object
    end,

    -- Gets a LinkCategory from the static map by its index.
    --
    -- Args:
    -- * index: Index of the LinkCategory to look for.
    --
    -- Returns: The LinkCategory corresponding to the given index.
    --
    get = function(index)
        return Instances[index]
    end,
}

-- Map[index] -> LinkCategory: Static map containing all created LinkCategory objects.
Instances = ErrorOnInvalidRead.new()

return LinkCategory
