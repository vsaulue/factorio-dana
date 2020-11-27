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

local AbstractGui = require("lua/gui/AbstractGui")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local MetaUtils = require("lua/class/MetaUtils")

local Metatable
local NewQueryButton
local ViewGraphButton
local ViewLegendButton

-- Instanciated GUI of a GraphMenuFlow.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller (override): GraphMenuFlow.
-- * mainFlow: LuaGuiElement. Top-level element of this GUI.
-- * newQueryButton: NewQueryButton. Button to create a new query.
-- * viewGraphButton: ViewGraphButton. Button to move the camera on the graph.
-- * viewLegendButton: ViewLegendButton. Button to move the camera on the legend.
-- + AbstractGui.
--
local GuiGraphMenuFlow = ErrorOnInvalidRead.new{
    -- Creates a new GuiGraphMenuFlow object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiGraphMenuFlow. The `object` argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)
        local controller = object.controller

        object.mainFlow = object.parent.add{
            type = "flow",
            direction = "horizontal",
        }

        object.newQueryButton = NewQueryButton.new{
            controller = controller,
            rawElement = GuiAlign.makeVerticallyCentered(object.mainFlow, {
                type = "button",
                caption = {"dana.apps.graph.newQuery"},
            })
        }
        object.viewGraphButton = ViewGraphButton.new{
            controller = controller,
            rawElement = GuiAlign.makeVerticallyCentered(object.mainFlow, {
                type = "button",
                caption = {"dana.apps.graph.moveToGraph"},
            })
        }
        object.viewLegendButton = ViewLegendButton.new{
            controller = controller,
            rawElement = GuiAlign.makeVerticallyCentered(object.mainFlow, {
                type = "button",
                caption = {"dana.apps.graph.moveToLegend"},
            })
        }

        return object
    end,

    -- Restores the metatable of a GuiGraphMenuFlow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        NewQueryButton.setmetatable(object.newQueryButton)
        ViewGraphButton.setmetatable(object.viewGraphButton)
        ViewLegendButton.setmetatable(object.viewLegendButton)
    end,
}

-- Metatable of the GuiGraphMenuFlow class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Implements AbstractGui:close().
        close = function(object)
            GuiElement.safeDestroy(object.mainFlow)
            object.newQueryButton:close()
            object.viewGraphButton:close()
            object.viewLegendButton:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.mainFlow.valid
        end,
    },
})

-- Button to switch to the query app.
--
-- RO Fields:
-- * app: GraphApp owning this button.
--
NewQueryButton = GuiElement.newSubclass{
    className = "GraphApp/NewQueryButton",
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self)
            self.controller.appInterface:newQuery()
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
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller.appInterface:viewGraphCenter()
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
    mandatoryFields = {"controller"},
    __index = {
        onClick = function(self, event)
            self.controller.appInterface:viewLegend()
        end,
    }
}

return GuiGraphMenuFlow
