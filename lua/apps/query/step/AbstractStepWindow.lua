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
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "queryApp/AbstractStepWindow"}

-- Base class for windows of the QueryApp.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * appInterface: QueryAppInterface. Callbacks to the upper controller.
-- * stepName: string. Class identifier of this AbstractStepWindow.
-- + AbstractGuiController.
--
local AbstractStepWindow = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractStepWindow objects.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.stepName
        end,
    },

    Metatable = MetaUtils.derive(AbstractGuiController.Metatable, {
        __index = {
            -- Implements AbstractGuiController:getGuiUpcalls.
            getGuiUpcalls = function(self)
                return self.appInterface.appResources
            end,
        },
    }),

    -- Creates a new AbstractStepWindow object.
    --
    -- Args:
    -- * object: table. Required fields: appInterface, stepName.
    -- * metatable:
    --
    -- Returns: The argument turned into an AbstractStepWindow object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "appInterface")
        cLogger:assertField(object, "stepName")
        return AbstractGuiController.new(object, metatable)
    end,

    setmetatable = AbstractGuiController.setmetatable,
}

return AbstractStepWindow
