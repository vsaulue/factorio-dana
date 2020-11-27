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
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "AbstractApp"}

local Metatable

-- Class representing an application.
--
-- RO Fields:
-- * appName: string. Unique identifier of this application's class.
-- * appResources: AppResources. Resources available to this application.
--
local AbstractApp = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractApp objects.
    Factory = AbstractFactory.new{
        enableMake = true,

        getClassNameOfObject = function(object)
            return object.appName
        end,
    },

    -- Metatable of the AbstractApp class.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Releases all API resources of this object.
            --
            -- Args:
            -- * self: AbstractApp object.
            --
            close = function(self) end,

            -- Hides all GUI elements of this application.
            --
            -- Args:
            -- * self: AbstractApp object.
            --
            hide = function(self) end,

            -- Function to call when a selection-tool is used by the player owning this app.
            --
            -- Args:
            -- * self: AbstractApp object.
            -- * event: Factorio event associated to the selection (from on_player_selected_area).
            --
            onSelectedArea = function(self, event) end,

            -- Rebuils any opened GUI that is not valid.
            --
            -- Args:
            -- * self: AbstractApp.
            --
            repairGui = function(self) end,

            -- Shows all GUI elements of this application.
            --
            -- Args:
            -- * self: AbstractApp object.
            --
            show = function(self) end,
        },
    },

    -- Creates a new AbstractApp object.
    --
    -- Args:
    -- * object: Table to modify.
    -- * metatable: Metatable to set.
    --
    -- Returns: The argument turned into an AbstractApp object.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "appName")
        cLogger:assertField(object, "appResources")
        setmetatable(object, metatable or Metatable)
        return object
    end,
}

Metatable = AbstractApp.Metatable

return AbstractApp
