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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local LayoutParameters = require("lua/layouts/LayoutParameters")

local cLogger = ClassLogger.new{className = "SimpleRenderer"}

local Red = {r = 1, a = 1}
local White = {r = 1, g = 1, b = 1, a = 1}
local DarkGrey = {r = 0.1, g = 0.1, b = 0.1, a = 1}
local LightGrey = {r = 0.2, g = 0.2, b = 0.2, a = 1}

local draw
local DefaultLayoutParameters
local Metatable
local renderTree

-- Class used to render graphs onto a LuaSurface.
--
-- RO properties:
-- * layout: Layout displayed by this renderer.
-- * rawPlayer: Lua player using this renderer.
-- * surface: surface on which the graph is displayed.
--
-- Methods: see Metatable.__index.
--
local SimpleRenderer = ErrorOnInvalidRead.new{
    -- Creates a new renderer.
    --
    -- Args:
    -- * object to turn into a SimpleRenderer object.
    --
    -- Returns: the argument turned into a SimpleRenderer object.
    --
    new = function(object)
        cLogger:assertField(object, "surface")
        cLogger:assertField(object, "rawPlayer")
        local layout = cLogger:assertField(object, "layout")
        object.layoutCoordinates = layout:computeCoordinates(DefaultLayoutParameters)
        ErrorOnInvalidRead.setmetatable(object)
        draw(object)
        return object
    end,
}

-- LayoutParameters object, used by all instances of SimpleRenderer.
DefaultLayoutParameters = LayoutParameters.new{
    edgeMarginX = 0.2,
    edgeMarginY = 0.2,
    edgeMinX = 1.6,
    edgeMinY = 1.6,
    linkWidth = 0.25,
    vertexMarginX = 0.2,
    vertexMarginY = 0.2,
    vertexMinX = 1.6,
    vertexMinY = 1.6,
}

-- Draws the graph.
--
-- Args:
-- * self: SimpleRenderer object.
--
draw = function(self)
    local layoutCoordinates = self.layoutCoordinates
    for vertexIndex,coords in pairs(layoutCoordinates.vertices) do
        rendering.draw_rectangle({
            color = LightGrey,
            draw_on_ground = true,
            filled = true,
            left_top = {coords.xMin, coords.yMin},
            players = {self.rawPlayer},
            right_bottom = {coords.xMax, coords.yMax},
            surface = self.surface,
        })
        rendering.draw_sprite({
            players = {self.rawPlayer},
            sprite = vertexIndex.type .. "/" .. vertexIndex.rawPrototype.name,
            surface = self.surface,
            target = {(coords.xMin + coords.xMax) / 2, (coords.yMin + coords.yMax) / 2},
        })
    end
    for edgeIndex,coords in pairs(layoutCoordinates.edges) do
        rendering.draw_rectangle({
            color = DarkGrey,
            draw_on_ground = true,
            filled = true,
            left_top = {coords.xMin, coords.yMin},
            players = {self.rawPlayer},
            right_bottom = {coords.xMax, coords.yMax},
            surface = self.surface,
        })
        rendering.draw_sprite({
            players = {self.rawPlayer},
            sprite = edgeIndex.type .. "/" .. edgeIndex.rawPrototype.name,
            surface = self.surface,
            target = {(coords.xMin + coords.xMax) / 2, (coords.yMin + coords.yMax) / 2},
        })
    end
    for rendererLink in pairs(layoutCoordinates.links) do
        local color = White
        if rendererLink.category == "backward" then
            color = Red
        end
        renderTree(self, rendererLink.tree, color)
    end
end

-- Renders a tree link.
--
-- TODO: non-recursive implementation
--
-- Args:
-- * self: SimpleRenderer object.
-- * tree: The tree link to render.
-- * color: Color used to draw the link.
--
renderTree = function(self,tree,color)
    local from = {tree.x, tree.y}
    local count = 0
    for subtree in pairs(tree.children) do
        count = count + 1
        rendering.draw_line({
            color = color,
            draw_on_ground = true,
            from = from,
            players = {self.rawPlayer},
            surface = self.surface,
            to = {subtree.x, subtree.y},
            width = 1,
        })
        renderTree(self, subtree, color)
    end
    if rawget(tree, "parent") then
        count = count + 1
    end
    if count > 2 then
        rendering.draw_circle({
            color = color,
            draw_on_ground = true,
            filled = true,
            players = {self.rawPlayer},
            radius = 0.125,
            surface = self.surface,
            target = from,
        })
    end
end

return SimpleRenderer
