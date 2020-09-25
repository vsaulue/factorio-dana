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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local IntermediatesDatabase = require("lua/model/IntermediatesDatabase")
local Logger = require("lua/logger/Logger")
local SimpleCyclesDatabase = require("lua/model/SimpleCyclesDatabase")
local TransformsDatabase = require("lua/model/TransformsDatabase")

local Metatable

-- Object holding prototypes wrapper for this mod.
--
-- Two goals:
-- * Associate a unique Lua object for each LuaPrototype (making them usable as table keys).
-- * Attach any useful data for the mod.
--
-- RO properties:
-- * intermediates: IntermediatesDatabase golding all the Intermediate objects.
-- * transforms: TransformsDatabase holding all the AbstractTransform objects.
-- * simpleCycles: SimpleCyclesDatabase holding the simple cycles of `transforms`.
--
-- Methods:
-- * rebuild: drops the current content of the database, and rebuild it from scratch.
--
local PrototypeDatabase = ErrorOnInvalidRead.new{
    -- Creates a new PrototypeDatabase object.
    --
    -- Args:
    -- * gameScript: LuaGameScript object containing the initial prototypes.
    --
    -- Returns: A PrototypeDatabase object, populated from the argument.
    --
    new = function(gameScript)
        local intermediates = IntermediatesDatabase.new()
        local transforms = TransformsDatabase.new{
            intermediates = intermediates,
        }
        local result = {
            intermediates = intermediates,
            transforms = transforms,
            simpleCycles = SimpleCyclesDatabase.new{
                transforms = transforms,
            },
        }
        setmetatable(result, Metatable)
        result:rebuild(gameScript)
        return result
    end,

    -- Restores the metatable of a PrototypeDatabase object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        IntermediatesDatabase.setmetatable(object.intermediates)
        TransformsDatabase.setmetatable(object.transforms)
        SimpleCyclesDatabase.setmetatable(object.simpleCycles)
    end,
}


-- Metatable of the PrototypeDatabase class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Resets the content of the database.
        --
        -- Args:
        -- * self: PrototypeDatabase object.
        -- * gameScript: game object holding the new prototypes.
        --
        rebuild = function(self, gameScript)
            self.intermediates:rebuild(gameScript)
            self.transforms:rebuild(gameScript)
            self.simpleCycles:rebuild()
        end,
    },
}

return PrototypeDatabase
