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

local Aabb = require("lua/canvas/Aabb")
local AbstractApp = require("lua/apps/AbstractApp")
local Canvas = require("lua/canvas/Canvas")
local ClassLogger = require("lua/logger/ClassLogger")
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GraphAppInterface = require("lua/apps/graph/GraphAppInterface")
local GraphMenuFlow = require("lua/apps/graph/gui/GraphMenuFlow")
local HyperPreprocessor = require("lua/layouts/preprocess/HyperPreprocessor")
local SelectionWindow = require("lua/apps/graph/gui/SelectionWindow")
local LayerLayout = require("lua/layouts/layer/LayerLayout")
local SimpleRenderer = require("lua/renderers/simple/SimpleRenderer")

local cLogger = ClassLogger.new{className = "GraphApp"}

local AppName
local makeEdge
local Metatable

-- Application to display a crafting hypergraph.
--
-- Implements GraphAppInterface.
--
-- RO fields:
-- * canvas: Canvas. Object on which the graph is drawn.
-- * graph: DirectedHypergraph. Displayed graph.
-- * guiSelection: SelectionWindow. Window displaying the selected items of the graph.
-- * menuFlow: GraphMenuFlow. Controller of the menu buttons.
-- * renderer: SimpleRenderer. Renderer displaying the graph.
-- * vertexDists: Map[vertexIndex] -> int. suggested partial order of vertices.
-- + inherited from AbstractApp.
--
local GraphApp = ErrorOnInvalidRead.new{
    -- Creates a new GraphApp object.
    --
    -- Args:
    -- * object: table. Required fields: appResources, graph, vertexDists.
    --
    -- Returns: The argument turned into a GraphApp object.
    --
    new = function(object)
        local graph = cLogger:assertField(object, "graph")
        local vertexDists = cLogger:assertField(object, "vertexDists")
        object.appName = AppName

        AbstractApp.new(object, Metatable)

        local rawPlayer = object.appResources.rawPlayer
        local prepGraph,prepDists = HyperPreprocessor.run(graph, vertexDists)
        local layout = LayerLayout.new{
            prepGraph = prepGraph,
            prepDists = prepDists,
        }
        local canvas = Canvas.new{
            players = {rawPlayer},
            surface = object.appResources.surface,
        }
        object.canvas = canvas
        object.renderer = SimpleRenderer.new{
            canvas = canvas,
        }
        object.renderer:drawLayout(layout)
        object.guiSelection = SelectionWindow.new{
            appResources = object.appResources,
            location = {0,50},
            maxHeight = rawPlayer.display_resolution.height - 50,
        }

        object.menuFlow = GraphMenuFlow.new{
            appInterface = object,
        }
        object.appResources:setAppMenu(object.menuFlow)


        object:viewGraphCenter()

        return object
    end,

    -- Restores the metatable of a GraphApp object, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        Canvas.setmetatable(object.canvas)
        DirectedHypergraph.setmetatable(object.graph)
        GraphMenuFlow.setmetatable(object.menuFlow)
        SelectionWindow.setmetatable(object.guiSelection)
        SimpleRenderer.setmetatable(object.renderer)
        setmetatable(object, Metatable)
    end,
}

-- Unique name for this application.
AppName = "graph"

-- Metatable of the GraphApp class.
Metatable = {
    __index = {
        -- Overrides AbstractApp:close().
        close = function(self)
            self.canvas:close()
            self.guiSelection:close()
        end,

        -- Overrides AbstractApp:hide().
        hide = function(self)
            self.guiSelection:close()
        end,

        -- Implements GraphAppInterface:newQuery().
        newQuery = function(self)
            self.appResources:makeAndSwitchApp{
                appName = "query",
            }
        end,

        -- Overrides AbstractApp:show().
        show = function(self)
            self.guiSelection:open(self.appResources.rawPlayer.gui.screen)
        end,

        -- Overrides AbstractApp:onSelectedArea().
        onSelectedArea = function(self, event)
            if event.item == "dana-select" then
                local left_top = event.area.left_top
                local right_bottom = event.area.right_bottom
                local aabb = Aabb.new{
                    xMin = left_top.x,
                    xMax = right_bottom.x,
                    yMin = left_top.y,
                    yMax = right_bottom.y,
                }
                local canvasSelection = self.canvas:makeSelection(aabb)
                local rendererSelection = self.renderer:makeRendererSelection(canvasSelection)
                self.guiSelection:setSelection(rendererSelection)
            end
        end,

        -- Overrides AbstractApp:repairGui().
        repairGui = function(self)
            self.guiSelection:repair(self.appResources.rawPlayer.gui.screen)
        end,

        -- Implements GraphAppInterface:viewGraphCenter().
        viewGraphCenter = function(self)
            local lc = self.renderer.layoutCoordinates
            if lc.xMin ~= math.huge then
                self.appResources:setPosition{
                    x = (lc.xMin + lc.xMax) / 2,
                    y = (lc.yMin + lc.yMax) / 2,
                }
            end
        end,

        -- Implements GraphAppInterface:viewLegend().
        viewLegend = function(self)
            local legendPos = rawget(self.renderer, "legendCenter")
            if legendPos then
                self.appResources:setPosition(self.renderer.legendCenter)
            end
        end,
    },
}
setmetatable(Metatable.__index, AbstractApp.Metatable.__index)
GraphAppInterface.checkMethods(Metatable.__index)

AbstractApp.Factory:registerClass(AppName, GraphApp)
return GraphApp
