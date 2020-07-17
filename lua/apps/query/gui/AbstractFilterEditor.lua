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

local cLogger = ClassLogger.new{className = "queryApp/AbstractFilterEditor"}

-- Class for GUIs used to edit an AbstractQueryFilter.
--
-- RO Fields:
-- * appResources: AppResources of the application owning this GUI.
-- * filter: AbstractQueryFilter modified by this GUI.
-- * root: LuaGuiElement in which the GUI is created.
--
local AbstractFilterEditor = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractFilterEditor objects.
    Factory = AbstractFactory.new{
        enableMake = true,

        getClassNameOfObject = function(object)
            return object.filter.filterType
        end,
    },

    -- Creates a new AbstractFilterEditor object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractFilterEditor object.
    --
    -- Returns: The argument turned into an AbstractFilterEditor object.
    --
    new = function(object)
        cLogger:assertField(object, "appResources")
        cLogger:assertField(object, "filter")
        cLogger:assertField(object, "root")
        return object
    end,
}

return AbstractFilterEditor
