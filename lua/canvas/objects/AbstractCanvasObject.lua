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

local cLogger = ClassLogger.new{className = "AbstractCanvasObject"}

local apiDestroy = rendering.destroy
local Metatable

-- Class wrapping basic rendering primitives of the api.
--
-- Implements close(), which must be called to free API resources.
--
-- RO fields:
-- * id: ID of the wrapped object in the rendering API.
-- * type: string encoding the type of canvas object (same value as rendering.get_type(id) ).
--
-- Methods: see Metatable.__index.
--
local AbstractCanvasObject = ErrorOnInvalidRead.new{
    -- Creates a new AbstractCanvasObject.
    --
    -- Args:
    -- * object: Table to turn into a AbstractCanvasObject.
    -- * metatable: Actual metatable to set (or nil to use the abstract one).
    --
    -- Returns: The argument, turned into a AbstractCanvasObject.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "id")
        cLogger:assertField(object, "type")
        setmetatable(object, metatable or Metatable)
        return object
    end,

    -- Metatable of the AbstractCanvasObject class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Tests if this objects collides with an Aabb object.
            --
            -- Args:
            -- * self: AbstractCanvasObject instance.
            -- * aabb: Aabb object to test collision with.
            --
            -- Return: true if the object collides with the Aabb. False otherwise.
            --
            isCollidingWithAabb = nil, -- abstract method: to be implemented by derived classes.

            -- Releases all API resources of this object.
            --
            -- Args:
            -- * self: AbstractCanvasObject instance.
            --
            close = function(self)
                apiDestroy(self.id)
                self.id = nil
            end,
        },

        __gc = function(self)
            local id = rawget(self, "id")
            if id then
                cLogger.warn("object was not properly closed before garbage collection.")
                apiDestroy(id)
            end
        end,
    },
}

Metatable = AbstractCanvasObject.Metatable

return AbstractCanvasObject
