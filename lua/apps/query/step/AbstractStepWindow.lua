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

local AbstractFactory = require("lua/class/AbstractFactory")
local AbstractGuiController = require("lua/gui/AbstractGuiController")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")

local cLogger = ClassLogger.new{className = "queryApp/AbstractStepWindow"}

-- Base class for windows of the QueryApp.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * app: QueryApp object owning this window.
-- * stepName: String indicating the type of step window.
-- + AbstractGuiController.
--
local AbstractStepWindow = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractStepWindow objects.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.stepName
        end,
    },

    Metatable = AbstractGuiController.Metatable,

    -- Creates a new AbstractStepWindow object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractStepWindow object (required fields: app, stepName).
    --
    -- Returns: The argument turned into an AbstractStepWindow object.
    --
    new = function(object, metatable)
        local app = cLogger:assertField(object, "app")
        cLogger:assertField(object, "stepName")

        return AbstractGuiController.new(object, metatable)
    end,

    setmetatable = AbstractGuiController.setmetatable,
}

return AbstractStepWindow
