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
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")

local GuiConstructorArgs
local Metatable
local SelectToolButton

-- Instanciated GUI of an SelectionWindow.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller: SelectionWindow. Owner of this GUI.
-- * frame: LuaGuiElement. Top-level element of this GUI.
-- * parent: LuaGuiElement. Element containing this GUI.
-- * selectToolButton: SelectToolButton of this window.
--
local GuiSelectionWindow = ErrorOnInvalidRead.new{
    new = function(object)
        AbstractGui.new(object, Metatable)
        local controller = object.controller

        local frame = GuiMaker.run(object.parent, GuiConstructorArgs)
        frame.selectToolButton.style.horizontally_stretchable = true
        object.frame = frame

        object.selectToolButton = SelectToolButton.new{
            gui = object,
            rawElement = frame.selectToolButton,
        }

        for _,panel in ipairs(controller.panels) do
            panel:open(frame)
        end

        object:setHasElements(controller:hasElements())
        object:updateLocation()
        object:updateMaxHeight()
        return object
    end,

    -- Restores the metatable of an GuiSelectionWindow, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        SelectToolButton.setmetatable(object.selectToolButton)
    end,
}

-- Metatable of the GuiSelectionWindow class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index= {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.frame)
            self.selectToolButton:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.frame.valid
        end,

        -- Handles modifications of the `elements` field of the controller.
        --
        -- Args:
        -- * self: GuiSelectionWindow.
        -- * hasElements: boolean. Flag indicating if controller currently displays any element.
        --
        setHasElements = function(self, hasElements)
            if self:sanityCheck() then
                self.frame.noSelection.visible = not hasElements
            end
        end,

        -- Handles modifications of the `location` field of the controller.
        --
        -- Args:
        -- * self: GuiSelectionWindow.
        --
        updateLocation = function(self)
            if self:sanityCheck() then
                local frame = self.frame
                if frame.location then
                    frame.location = self.controller.location
                end
            end
        end,

        -- Handles modifications of the `maxHeight` field of the controller.
        --
        -- Args:
        -- * self: GuiSelectionWindow.
        --
        updateMaxHeight = function(self)
            if self:sanityCheck() then
                self.frame.style.maximal_height = self.controller.maxHeight
            end
        end,
    },
})

-- GuiMaker arguments to build this GUI.
GuiConstructorArgs = {
    type = "frame",
    caption = {"dana.apps.graph.selectionWindow.title"},
    direction = "vertical",
    children = {
        {
            type = "button",
            name = "selectToolButton",
            caption = {"dana.apps.graph.selectionWindow.selectButton"},
        },{
            type = "label",
            name = "noSelection",
            caption = {"dana.apps.graph.selectionWindow.emptyCategory"},
        }
    },
}

-- Button to give the dana-select item to the player.
--
-- RO Fields:
-- * rawPlayer: Player to give the item to.
--
SelectToolButton = GuiElement.newSubclass{
    className = "GraphApp/SelectToolButton",
    mandatoryFields = {"gui"},
    __index = {
        onClick = function(self)
            self.gui.controller:giveSelectionTool()
        end,
    },
}

return GuiSelectionWindow
