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
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local SelectionWindow = require("lua/apps/graph/gui/SelectionWindow")
local LayerLayout = require("lua/layouts/layer/LayerLayout")
local SimpleRenderer = require("lua/renderers/simple/SimpleRenderer")

local cLogger = ClassLogger.new{className = "GraphApp"}

local AppName
local makeEdge
local Metatable
local NewQueryButton
local ViewGraphButton
local ViewLegendButton

-- Application to display a crafting hypergraph.
--
-- RO fields:
-- * canvas: Canvas object on which the graph is drawn.
-- * graph: Displayed DirectedHypergraph.
-- * guiSelection: SelectionWindow object, displaying the result of selections on the graph surface.
-- * newQueryButton: NewQueryButton object (top menu button to switch to the query app).
-- * renderer: SimpleRenderer object displaying the graph.
-- * vertexDists[vertexIndex] -> int: suggested partial order of vertices.
-- + inherited from AbstractApp.
--
local GraphApp = ErrorOnInvalidRead.new{
    -- Creates a new GraphApp object.
    --
    -- Args:
    -- * object: Table to turn into a GraphApp object (required fields: graph, rawPlayer, vertexDists, surface).
    --
    -- Returns: The argument turned into a GraphApp object.
    --
    new = function(object)
        local graph = cLogger:assertField(object, "graph")
        local vertexDists = cLogger:assertField(object, "vertexDists")
        object.appName = AppName

        AbstractApp.new(object, Metatable)

        local rawPlayer = object.appController.appResources.rawPlayer
        local layout = LayerLayout.new{
            graph = graph,
            vertexDists = vertexDists,
        }
        local canvas = Canvas.new{
            players = {rawPlayer},
            surface = object.appController.appResources.surface,
        }
        object.canvas = canvas
        object.renderer = SimpleRenderer.new{
            canvas = canvas,
        }
        object.renderer:drawLayout(layout)
        object.guiSelection = SelectionWindow.new{
            rawPlayer = rawPlayer,
        }

        local menuFlow = object.appController.appResources.menuFlow
        object.newQueryButton = NewQueryButton.new{
            app = object,
            rawElement = GuiAlign.makeVerticallyCentered(menuFlow, {
                type = "button",
                caption = {"dana.apps.graph.newQuery"},
            })
        }
        object.viewGraphButton = ViewGraphButton.new{
            app = object,
            rawElement = GuiAlign.makeVerticallyCentered(menuFlow, {
                type = "button",
                caption = {"dana.apps.graph.moveToGraph"},
            })
        }
        object.viewLegendButton = ViewLegendButton.new{
            app = object,
            rawElement = GuiAlign.makeVerticallyCentered(menuFlow, {
                type = "button",
                caption = {"dana.apps.graph.moveToLegend"},
            })
        }

        object:viewGraphCenter()

        return object
    end,

    -- Restores the metatable of a GraphApp object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        Canvas.setmetatable(object.canvas)
        DirectedHypergraph.setmetatable(object.graph)
        NewQueryButton.setmetatable(object.newQueryButton)
        ViewGraphButton.setmetatable(object.viewGraphButton)
        ViewLegendButton.setmetatable(object.viewLegendButton)
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
            self.guiSelection.frame.visible = false
        end,

        -- Moves the view to the center of the graph.
        --
        -- Args:
        -- * self: GraphApp object.
        --
        viewGraphCenter = function(self)
            local lc = self.renderer.layoutCoordinates
            if lc.xMin ~= math.huge then
                self.appController.appResources.positionController:setPosition{
                    x = (lc.xMin + lc.xMax) / 2,
                    y = (lc.yMin + lc.yMax) / 2,
                }
            end
        end,

        -- Overrides AbstractApp:show().
        show = function(self)
            self.guiSelection.frame.visible = true
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

        -- Moves the view to the legend of the graph.
        --
        -- Args:
        -- * self: GraphApp object.
        --
        viewLegend = function(self)
            local legendPos = rawget(self.renderer, "legendCenter")
            if legendPos then
                self.appController.appResources.positionController:setPosition(self.renderer.legendCenter)
            end
        end,
    },
}
setmetatable(Metatable.__index, AbstractApp.Metatable.__index)

-- Button to switch to the query app.
--
-- RO Fields:
-- * app: GraphApp owning this button.
--
NewQueryButton = GuiElement.newSubclass{
    className = "GraphApp/NewQueryButton",
    mandatoryFields = {"app"},
    __index = {
        onClick = function(self)
            self.app.appController:makeAndSwitchApp{
                appName = "query",
            }
        end,
    },
}

-- Button to move the player to the center of the graph.
--
-- RO Fields:
-- * app: GraphApp owning this button.
--
ViewGraphButton = GuiElement.newSubclass{
    className = "GraphApp/ViewGraphButton",
    mandatoryFields = {"app"},
    __index = {
        onClick = function(self, event)
            self.app:viewGraphCenter()
        end,
    },
}

-- Button to move the player to the legend of the graph.
--
-- RO Fields:
-- * app: GraphApp owning this button.
--
ViewLegendButton = GuiElement.newSubclass{
    className = "GraphApp/ViewLegendButton",
    mandatoryFields = {"app"},
    __index = {
        onClick = function(self, event)
            self.app:viewLegend()
        end,
    }
}

AbstractApp.Factory:registerClass(AppName, GraphApp)
return GraphApp
