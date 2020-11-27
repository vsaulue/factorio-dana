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
local GuiUpcalls = require("lua/gui/GuiUpcalls")

local cLogger = ClassLogger.new{className = "AppUpcalls"}

-- Interface containing callbacks from top-level controller for applications.
--
local AppUpcalls = ErrorOnInvalidRead.new{
    -- Checks that all methods are implemented.
    --
    -- Args:
    -- * object: AppUpcalls.
    --
    check = function(object)
        cLogger:assertField(object, "makeAndSwitchApp")
        cLogger:assertField(object, "setAppMenu")
        cLogger:assertField(object, "setPosition")
        GuiUpcalls.checkMethods(object)
    end,
}

--[[
Metatable = {
    __index = {
        -- Creates a new application, and runs it in place of the current one.
        --
        -- Args:
        -- * self: AppUpcalls.
        -- * newApp: table. Used to build the new AbstractApp.
        --
        makeAndSwitchApp = function(self, newApp) end,

        -- Implements GuiUpcalls:notifyGuiCorrupted().
        notifyGuiCorrupted = function(self) end,

        -- Sets the new application controller for the top-left menu.
        --
        -- Args:
        -- * self: AppUpcalls.
        -- * appMenu: AbstractGuiController. The new controller to use.
        --
        setAppMenu = function(self, appMenu) end,

        -- Sets the player's position on the app surface.
        --
        -- If the GUI is opened, the player is teleported. Otherwise the position will be stored for
        -- the next time the GUI is opened.
        --
        -- Args:
        -- * self: AppUpcalls.
        -- * position: table. Position object (see Factorio API).
        --
        setPosition = function(self, position) end,
    },
}
--]]

return AppUpcalls
