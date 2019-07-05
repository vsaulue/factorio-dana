-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local LayoutParameters = require("lua/LayoutParameters")

-- Class used to render graphs onto a LuaSurface.
--
-- RO properties:
-- * surface: surface on which the graph is displayed.
-- * rawPlayer: Lua player using this renderer.
--
local SimpleRenderer = {
    new = nil,
}

-- Implementation stuff (private scope).
local Impl = {
    -- LayoutParameters object, used by all instances of SimpleRenderer.
    LayoutParameters = LayoutParameters.new(),

    -- Metatable of the SimpleRenderer class.
    Metatable = {
        __index = {
            draw = nil, -- implemented later
        },
    },

    renderTree = nil, -- implemented later

    Red = {r = 1, a = 1},
    White = {r = 1, g = 1, b = 1, a = 1},
}

-- Renders a tree link.
--
-- TODO: non-recursive implementation
--
-- Args:
-- * self: SimpleRenderer object.
-- * tree: The tree link to render.
-- * color: Color used to draw the link.
--
function Impl.renderTree(self,tree,color)
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
        Impl.renderTree(self, subtree, color)
    end
    if count > 1 then
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

-- Draws a graph.
--
-- Args:
-- * self: SimpleRenderer instance.
-- * layout: LayerLayout object to draw.
--
function Impl.Metatable.__index.draw(self,layout)
    local layoutCoordinates = layout:computeCoordinates(Impl.LayoutParameters)
    for vertexIndex,coordinates in pairs(layoutCoordinates.vertices) do
        rendering.draw_sprite({
            players = {self.rawPlayer},
            sprite = vertexIndex.type .. "/" .. vertexIndex.rawPrototype.name,
            surface = self.surface,
            target = {coordinates.xMin,coordinates.yMin},
        })
    end
    for edgeIndex,coordinates in pairs(layoutCoordinates.edges) do
        rendering.draw_sprite({
            players = {self.rawPlayer},
            sprite = edgeIndex.type .. "/" .. edgeIndex.rawPrototype.name,
            surface = self.surface,
            target = {coordinates.xMin,coordinates.yMin},
        })
    end
    for rendererLink in pairs(layoutCoordinates.links) do
        local color = Impl.White
        if rendererLink.category == "backward" then
            color = Impl.Red
        end
        Impl.renderTree(self, rendererLink.tree, color)
    end
end

-- Creates a new renderer.
--
-- Args:
-- * object to turn into a SimpleRendererInstance.
--
function SimpleRenderer.new(object)
    setmetatable(object, Impl.Metatable)
    return object
end

return SimpleRenderer
