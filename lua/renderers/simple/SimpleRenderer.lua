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
local LinkCategory = require("lua/layouts/LinkCategory")
local RendererSelection = require("lua/renderers/RendererSelection")
local SimpleConfig = require("lua/renderers/simple/SimpleConfig")
local SimpleLinkDrawer = require("lua/renderers/simple/SimpleLinkDrawer")
local SimpleTreeDrawer = require("lua/renderers/simple/SimpleTreeDrawer")

local cLogger = ClassLogger.new{className = "SimpleRenderer"}

local drawLegend
local drawLegendForLine
local drawLegendForNode
local drawLegendTitle
local Metatable
local makeNodeArgs
local renderTree

-- Class used to render graphs onto a LuaSurface.
--
-- RO properties:
-- * layoutCoordinates: LayoutCoordinates object being rendered.
-- * legendCenter (optional): {x=,y=} table indicating the center of the legend area (nil if no legend is drawn).
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
            local links = result.links
            local nodes = result.nodes
            for canvasObject in pairs(canvasSelection) do
                local rendererType = canvasObject.rendererType
                if rendererType == "node" then
                    local prepNodeIndex = canvasObject.rendererIndex
                    nodes[prepNodeIndex.type][prepNodeIndex] = true
                else
                    cLogger:assert(rendererType == "treeLinkNode", "Unknown renderer type.")
                    links[canvasObject.rendererIndex] = true
                end
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
            local layoutCoordinates = layout:computeCoordinates(SimpleConfig.LayoutParameters)
            self.layoutCoordinates = layoutCoordinates
            local canvas = self.canvas

            local nodeArgs = makeNodeArgs()
            nodeArgs.selectable = true
            for nodeIndex,node in pairs(layoutCoordinates.nodes) do
                local objects = node:drawOnCanvas(canvas, nodeArgs)
                for canvasObject in pairs(objects) do
                    canvasObject.rendererType = "node"
                    canvasObject.rendererIndex = nodeIndex
                end
                canvas:newSprite{
                    sprite = nodeIndex.index.spritePath,
                    target = {node:getMiddle()},
                }
            end

            local linkDrawer = SimpleLinkDrawer.new{
                canvas = canvas,
            }
            for rendererLink in pairs(layoutCoordinates.links) do
                SimpleTreeDrawer.run(linkDrawer, rendererLink)
            end

            drawLegend(self)
        end,
    }
}

-- Draws a legend at the top-left of the graph.
--
-- Args:
-- * self: SimpleRenderer object.
--
drawLegend = function(self)
    local LegendXLength = 20
    local canvas = self.canvas
    local params = SimpleConfig.LayoutParameters
    local xMin = self.layoutCoordinates.xMin
    if xMin == math.huge then
        xMin = 0
    end
    xMin = xMin - LegendXLength - 4
    local yMin = self.layoutCoordinates.yMin
    if yMin == math.huge then
        yMin = 0
    end
    local cursor = {
        x = xMin + 0.5,
        y = yMin + 0.5,
    }

    drawLegendTitle(canvas, cursor)

    drawLegendForNode(canvas, cursor, params.shapes.hyperVertex, {"dana.renderer.simple.legend.vertexText"})
    drawLegendForNode(canvas, cursor, params.shapes.hyperEdge, {"dana.renderer.simple.legend.edgeText"})
    drawLegendForNode(canvas, cursor, params.shapes.hyperOneToOne, {"dana.renderer.simple.legend.oneToOneText"})

    cursor.y = cursor.y + 0.75

    -- Links
    local linkDrawer = SimpleLinkDrawer.new{
        canvas = canvas,
        makeTriangle = true,
    }
    for categoryIndex,color in pairs(SimpleConfig.LinkCategoryToColor) do
        drawLegendForLine(linkDrawer, cursor, categoryIndex)
    end

    cursor.x = xMin + LegendXLength
    canvas:newRectangle{
        left_top = {xMin, yMin},
        right_bottom = cursor,
        color = SimpleConfig.LegendFrameColor,
        filled = false,
    }

    self.legendCenter = ErrorOnInvalidRead.new{
        x = (xMin + cursor.x) / 2,
        y = (yMin + cursor.y) / 2,
    }
end

-- Draws a line in the legend box, and adds a description on its right.
--
-- Args:
-- * lineDrawer: SimpleLinkDrawer object used to draw the lines.
-- * cursor: A {x=,y=} table indicating where to draw. The Y field will be incremented for the next legend element.
-- * linkCategoryIndex: Index of the link category to draw.
--
drawLegendForLine = function(linkDrawer, cursor, linkCategoryIndex)
    local xStart = cursor.x
    -- Line
    local length = SimpleConfig.LegendLinkLength
    linkDrawer:setLinkCategoryIndex(linkCategoryIndex)
    linkDrawer:setFrom(cursor.x, cursor.y)
    linkDrawer:setTo(cursor.x + length, cursor.y)
    linkDrawer:draw()
    -- Text
    cursor.y = cursor.y - 0.6
    cursor.x = xStart + length + 0.5
    linkDrawer.canvas:newText{
        text = LinkCategory.get(linkCategoryIndex).localisedDescription,
        target = cursor,
        color = SimpleConfig.LegendTextColor,
        scale = 2,
    }
    -- Position for the next line
    cursor.y = cursor.y + 2.5
    cursor.x = xStart
end

-- Draws a node in the legend box, and adds a description on its right.
--
-- Args:
-- * canvas: Canvas object on which element will be drawn.
-- * cursor: A {x=,y=} table indicating where to draw. The Y field will be incremented for the next legend element.
-- * shape: AbstractNodeShape object of the node to draw.
-- * localisedText: Localised string to display near the rectangle.
--
drawLegendForNode = function(canvas, cursor, shape, localisedText)
    local xStart = cursor.x
    -- Node
    local rendererArgs = makeNodeArgs()
    local node = shape:generateNode(0)
    node:setXMin(xStart)
    node:setYMin(cursor.y)
    node:drawOnCanvas(canvas, rendererArgs)
    -- Text
    cursor.x = xStart + node:getXLength() + 0.5
    cursor.y = cursor.y + 0.2
    canvas:newText{
        text = localisedText,
        target = cursor,
        color = SimpleConfig.LegendTextColor,
        scale = 2,
    }
    -- Position for the next line
    cursor.y = cursor.y + 2
    cursor.x = xStart
end

-- Draws a title for the legend box.
--
-- Args:
-- * canvas: Canvas object on which element will be drawn.
-- * cursor: A {x=,y=} table indicating where to draw. The Y field will be incremented for the next legend element.
--
drawLegendTitle = function(canvas, cursor)
    canvas:newText{
        text = {"dana.renderer.simple.legend.title"},
        target = cursor,
        color = SimpleConfig.LegendTextColor,
        scale = 5,
    }
    -- Position for the next line
    cursor.y = cursor.y + 4
end

-- Makes common constructor arguments for the background shape of nodes.
--
-- Returns: A partially filled table usable in Canvas:makeXXX().
--
makeNodeArgs = function()
    return {
        color = SimpleConfig.NodeColor,
        draw_on_ground = true,
        filled = true,
    }
end

return SimpleRenderer
