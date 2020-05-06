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

local CanvasObject = require("lua/canvas/CanvasObject")
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
        setmetatable(object, Metatable)
        return object
    end,
}

-- Adds a new CanvasObject.
--
-- Args:
-- * self: Canvas instance.
-- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
-- * drawFunction: Function from the rendering API to call to generate the API id.
--
-- Returns: The new CanvasObject.
--
drawWrapper = function(self, initData, drawFunction)
    initData.surface = self.surface
    initData.players = self.players
    local id = drawFunction(initData)
    local result = CanvasObject.new{
        id = id,
    }
    self.objects[id] = result
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

        -- Draws a new line.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newLine = function(self, initData)
            return drawWrapper(self, initData, rendering.draw_line)
        end,

        -- Draws a new circle.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newCircle = function(self, initData)
            return drawWrapper(self, initData, rendering.draw_circle)
        end,

        -- Draws a new rectangle.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newRectangle = function(self, initData)
            return drawWrapper(self, initData, rendering.draw_rectangle)
        end,

        -- Draws a new sprite.
        --
        -- Args:
        -- * self: Canvas object.
        -- * initData: Arguments passed to the rendering API (surface & players are filled by this method).
        --
        newSprite = function(self, initData)
            return drawWrapper(self, initData, rendering.draw_sprite)
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
