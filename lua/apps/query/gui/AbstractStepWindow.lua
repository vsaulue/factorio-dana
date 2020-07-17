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

local AbstractFactory = require("lua/AbstractFactory")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")

local cLogger = ClassLogger.new{className = "queryApp/AbstractStepWindow"}

local Metatable

-- Base class for windows of the QueryApp.
--
-- RO Fields:
-- * app: QueryApp object owning this window.
-- * frame: Frame object from Factorio (LuaGuiElement).
-- * stepName: String indicating the type of step window.
--
local AbstractStepWindow = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractStepWindow objects.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.stepName
        end,
    },

    -- Metatable of the AbstractStepWindow class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Releases all API resources of this object.
            --
            -- Args:
            -- * self: QueryEditor object.
            --
            close = function(self)
                GuiElement.destroy(self.frame)
            end,
        },
    },

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

        object.frame = app.appController.appResources.rawPlayer.gui.center.add{
            type = "frame",
            direction = "vertical",
        }

        setmetatable(object, metatable or Metatable)
        return object
    end,
}

Metatable = AbstractStepWindow.Metatable

return AbstractStepWindow
