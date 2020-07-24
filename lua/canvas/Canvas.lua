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

local AbstractCanvasObject = require("lua/canvas/objects/AbstractCanvasObject")
local CanvasCircle = require("lua/canvas/objects/CanvasCircle")
local CanvasLine = require("lua/canvas/objects/CanvasLine")
local CanvasPolygon = require("lua/canvas/objects/CanvasPolygon")
local CanvasRectangle = require("lua/canvas/objects/CanvasRectangle")
local CanvasSprite = require("lua/canvas/objects/CanvasSprite")
local CanvasText = require("lua/canvas/objects/CanvasText")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "Canvas"}
local drawWrapper
local Metatable

-- Class abstracting the Factorio rendering API for renderers.
--
-- Implements close(), which must be called to free API resources.
--
-- RO fields:
-- * objects[id]: Map of CanvasObject held by this Canvas, indexed by their `id` field.
-- * players: luaArray of LuaPlayer objects, passed to the rendering API.
-- * selectable: Set of selectable objects.
-- * surface: LuaSurface where the objects are drawn.
--
local Canvas = ErrorOnInvalidRead.new{
    -- Creates a new Canvas object.
    --
    -- Args:
    -- * object: Table to turn into a Canvas instance.
    --
    -- Returns: The argument turned into a Canvas object.
    --
    new = function(object)
        cLogger:assertField(object, "players")
        cLogger:assertField(object, "surface")
        object.objects = ErrorOnInvalidRead.new()
        object.selectable = ErrorOnInvalidRead.new()
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a Canvas instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object.objects)
        for _,canvasObject in pairs(object.objects) do
            AbstractCanvasObject.Factory:restoreMetatable(canvasObject)
        end
        ErrorOnInvalidRead.setmetatable(object.selectable)
        setmetatable(object, Metatable)
    end,
}

-- Adds a new CanvasObject.
--
-- Args:
-- * self: Canvas instance.
-- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
-- * class: "Class" to instanciate (the "Class" is the table returned by require).
--
-- Returns: The new CanvasObject.
--
drawWrapper = function(self, initData, class)
    initData.surface = self.surface
    initData.players = self.players
    local result = class.makeFromInitData(initData)
    self.objects[result.id] = result
    if initData.selectable then
        cLogger:assertField(result, "isCollidingWithAabb")
        self.selectable[result] = true
    end
    return result
end

-- Metatable of the Canvas class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Releases all API resources of this object.
        --
        -- Args:
        -- * self: Canvas instance.
        --
        close = function(self)
            for id,object in pairs(self.objects) do
                object:close()
            end
            self.objects = nil
        end,

        -- Gets all the selectable objects intersecting/colliding the given Aabb.
        --
        -- Note: naive implementation for now. Might have to add a space partitioning data structure
        -- at some point to keep performances reasonable on larger scenes.
        --
        -- args:
        -- * self: Canvas instance.
        -- * aabb: Aabb object.
        --
        -- Returns: a set containing all the selectable objects colliding with the given Aabb.
        --
        makeSelection = function(self, aabb)
            local result = ErrorOnInvalidRead.new()
            for object in pairs(self.selectable) do
                if object:isCollidingWithAabb(aabb) then
                    result[object] = true
                end
            end
            return result
        end,

        -- Draws a new line.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newLine = function(self, initData)
            return drawWrapper(self, initData, CanvasLine)
        end,

        -- Draws a new circle.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newCircle = function(self, initData)
            return drawWrapper(self, initData, CanvasCircle)
        end,

        -- Draws a new polygon.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newPolygon = function(self, initData)
            return drawWrapper(self, initData, CanvasPolygon)
        end,

        -- Draws a new rectangle.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newRectangle = function(self, initData)
            return drawWrapper(self, initData, CanvasRectangle)
        end,

        -- Draws a new sprite.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newSprite = function(self, initData)
            return drawWrapper(self, initData, CanvasSprite)
        end,

        -- Draws a new text.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newText = function(self, initData)
            return drawWrapper(self, initData, CanvasText)
        end,
    },

    __gc = function(self)
        local objects = rawget(self, "objects")
        if objects then
            cLogger.warn("object was not properly closed before garbage collection.")
            self:close()
        end
    end,
}

return Canvas
