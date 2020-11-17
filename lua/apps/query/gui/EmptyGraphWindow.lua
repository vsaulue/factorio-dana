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

local AbstractGuiController = require("lua/gui/AbstractGuiController")
local AbstractStepWindow = require("lua/apps/query/gui/AbstractStepWindow")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiEmptyGraphWindow = require("lua/apps/query/gui/GuiEmptyGraphWindow")

local BackButton
local Metatable
local StepName

-- Window shown when a query generated an empty graph.
--
-- Inherits from AbstractGuiController, AbstractStepWindow.
--
-- RO Fields:
-- * backButton: BackButton object of this window.
--
local EmptyGraphWindow = ErrorOnInvalidRead.new{
    -- Creates a new EmptyGraphWindow object.
    --
    -- Args:
    -- * object: Table to turn into an EmptyGraphWindow object (required fields: see AbstractStepWindow).
    --
    -- Returns: The argument turned into an EmptyGraphWindow object.
    --
    new = function(object)
        object.stepName = StepName
        AbstractStepWindow.new(object, Metatable)
        object:open(object.app.appController.appResources.rawPlayer.gui.center)
        return object
    end,

    -- Restores the metatable of a EmptyGraphWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiEmptyGraphWindow.setmetatable)
        BackButton.setmetatable(object.backButton)
    end,
}

-- Metatable of the EmptyGraphWindow class.
Metatable = {
    __index = {
        close = AbstractGuiController.Metatable.__index.close,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiEmptyGraphWindow.new{
                controller = self,
                parent = parent,
            }
        end,

        open = AbstractGuiController.Metatable.__index.open,
    }
}
setmetatable(Metatable.__index, {__index = AbstractStepWindow.Metatable.__index})

-- Unique name for this step.
StepName = "emptyGraph"

AbstractStepWindow.Factory:registerClass(StepName, EmptyGraphWindow)
return EmptyGraphWindow
