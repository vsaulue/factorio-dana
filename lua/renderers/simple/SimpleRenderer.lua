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
local LayoutCoordinates = require("lua/layouts/LayoutCoordinates")
local LayoutParameters = require("lua/layouts/LayoutParameters")
local RendererSelection = require("lua/renderers/RendererSelection")

local cLogger = ClassLogger.new{className = "SimpleRenderer"}

local Red = {r = 1, a = 1}
local White = {r = 1, g = 1, b = 1, a = 1}
local DarkGrey = {r = 0.1, g = 0.1, b = 0.1, a = 1}
local LightGrey = {r = 0.2, g = 0.2, b = 0.2, a = 1}

local DefaultLayoutParameters
local Metatable
local renderTree

-- Class used to render graphs onto a LuaSurface.
--
-- RO properties:
-- * layoutCoordinates: LayoutCoordinates object being rendered.
-- * canvas: Canvas object on which the layout must be drawn.
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
        cLogger:assertField(object, "canvas")
        object.layoutCoordinates = nil
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a CanvasRectangle instance, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        LayoutCoordinates.setmetatable(object.layoutCoordinates)
    end,
}

-- Metatable of the SimpleRenderer class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Turns a selction from the underlying canvas into a RendererSelection object.
        --
        -- Args:
        -- * self: SimpleRenderer object.
        -- * canvasSelection: Set of CanvasObject from the underlying canvas.
        --
        -- Returns: A new RendererSelection with all items from canvasSelection.
        --
        makeRendererSelection = function(self, canvasSelection)
            local result = RendererSelection.new()
            local rendererTypeToTable = ErrorOnInvalidRead.new{
                edge = result.edges,
                vertex = result.vertices,
                treeLinkNode = result.links,
            }
            for canvasObject in pairs(canvasSelection) do
                rendererTypeToTable[canvasObject.rendererType][canvasObject.rendererIndex] = true
            end
            return result
        end,

        -- Draws the given layout.
        --
        -- NOTE: This does NOT clear any layout previously drawn !
        --
        -- Args:
        -- * self: SimpleRenderer object.
        -- * layout: Layout to draw.
        --
        drawLayout = function(self, layout)
            local layoutCoordinates = layout:computeCoordinates(DefaultLayoutParameters)
            self.layoutCoordinates = layoutCoordinates
            local canvas = self.canvas
            for vertexIndex,coords in pairs(layoutCoordinates.vertices) do
                local rectangle = canvas:newRectangle{
                    color = LightGrey,
                    draw_on_ground = true,
                    filled = true,
                    left_top = {coords.xMin, coords.yMin},
                    right_bottom = {coords.xMax, coords.yMax},
                    selectable = true
                }
                rectangle.rendererType = "vertex"
                rectangle.rendererIndex = vertexIndex
                canvas:newSprite{
                    sprite = vertexIndex.spritePath,
                    target = {(coords.xMin + coords.xMax) / 2, (coords.yMin + coords.yMax) / 2},
                }
            end
            for edgeIndex,coords in pairs(layoutCoordinates.edges) do
                local rectangle = canvas:newRectangle{
                    color = DarkGrey,
                    draw_on_ground = true,
                    filled = true,
                    left_top = {coords.xMin, coords.yMin},
                    right_bottom = {coords.xMax, coords.yMax},
                    selectable = true,
                }
                rectangle.rendererType = "edge"
                rectangle.rendererIndex = edgeIndex
                canvas:newSprite{
                    sprite = edgeIndex.spritePath,
                    target = {(coords.xMin + coords.xMax) / 2, (coords.yMin + coords.yMax) / 2},
                }
            end
            for rendererLink in pairs(layoutCoordinates.links) do
                local color = White
                if rendererLink.category == "backward" then
                    color = Red
                end
                renderTree(self, rendererLink.tree, color)
            end
        end,
    }
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
    local canvas = self.canvas
    local from = {tree.x, tree.y}
    local count = 0
    for subtree in pairs(tree.children) do
        count = count + 1
        local line = canvas:newLine{
            color = color,
            draw_on_ground = true,
            from = from,
            to = {subtree.x, subtree.y},
            width = 1,
            selectable = true
        }
        line.rendererType = "treeLinkNode"
        line.rendererIndex = subtree
        renderTree(self, subtree, color)
    end
    if rawget(tree, "parent") then
        count = count + 1
    end
    if count > 2 then
        canvas:newCircle{
            color = color,
            draw_on_ground = true,
            filled = true,
            radius = 0.125,
            target = from,
        }
    end
end

return SimpleRenderer
