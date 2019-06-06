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
    -- Metatable of the SimpleRenderer class.
    Metatable = {
        __index = {
            draw = nil, -- implemented later
        },
    },
}

-- Draws a graph.
--
-- Args:
-- * self: SimpleRenderer instance.
-- * layout: LayerLayout object to draw.
--
function Impl.Metatable.__index.draw(self,layout)
    for layerId,layer in ipairs(layout.layers.entries) do
        for vertexOrder,layerEntry in ipairs(layer) do
            rendering.draw_sprite({
                players = {self.rawPlayer},
                sprite = layerEntry.index.type .. "/" .. layerEntry.index.rawPrototype.name,
                surface = self.surface,
                target = {vertexOrder*4,layerId*4},
            })
        end
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
