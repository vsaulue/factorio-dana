-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local cLogger = ClassLogger.new{className = "AbstractParamsEditor"}

-- GUI controller to edit specific parameters in a query.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * editorName: string. Unique identifier of this type.
-- + AbstractGuiController.
--
local AbstractParamsEditor = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractParamsEditor objects.
    Factory = AbstractFactory.new{
        getClassNameOfObject = function(object)
            return object.editorName
        end,
    },

    -- Metatable of the AbstractParamsEditor class.
    Metatable = AbstractGuiController.Metatable,

    -- Creates a new AbstractParamsEditor object.
    --
    -- Args:
    -- * object: table. Required fields: editorName.
    -- * metatable: table. Metatable to set.
    --
    -- Returns: AbstractParamsEditor. The `object` argument turned into the desired type.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "editorName")
        return AbstractGuiController.new(object, metatable)
    end,

    -- Restores the metatable of a AbstractParamsEditor object, and all its owned objects.
    setmetatable = AbstractGuiController.setmetatable,
}

return AbstractParamsEditor
