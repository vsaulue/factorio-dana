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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "queryApp/AbstractParamsEditor"}

-- Class for GUIs used to edit some parameters of a query.
--
-- RO Fields:
-- * appResources: AppResources of the application owning this GUI.
-- * params: Query parameters modified by this GUI.
-- * root: LuaGuiElement in which the GUI is created.
--
local AbstractParamsEditor = ErrorOnInvalidRead.new{
    -- Creates a new AbstractParamsEditor object.
    --
    -- Args:
    -- * object: Table to turn into an AbstractParamsEditor object.
    --
    -- Returns: The argument turned into an AbstractParamsEditor object.
    --
    new = function(object)
        cLogger:assertField(object, "appResources")
        cLogger:assertField(object, "params")
        cLogger:assertField(object, "root")
        return object
    end,
}

return AbstractParamsEditor
