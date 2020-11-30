-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local cLogger = ClassLogger.new{className = "PlayerCtrlInterface"}

-- Interface containing callbacks of the player controller.
--
-- Implements GuiUpcalls.
--
local PlayerCtrlInterface = ErrorOnInvalidRead.new{
    -- Checks that all methods are implemented.
    --
    -- Args:
    -- * object: PlayerCtrlInterface.
    --
    check = function(object)
        cLogger:assertField(object, "hide")
        cLogger:assertField(object, "show")
        GuiUpcalls.checkMethods(object)
    end,
}

--[[
Metatable = {
    __index = {
        -- Hides the Dana GUI of this player, and teleports it back to the last position/surface.
        --
        -- Args:
        -- * self: Player object.
        -- * keepPosition: false to teleport the player at the the position he had while opening Dana.
        --   true to stay at the current position.
        --
        hide = function(self, keepPosition) end,

        -- Implements GuiUpcalls:notifyGuiCorrupted().
        notifyGuiCorrupted = function(self) end,

        -- Shows Dana's GUI, and moves the player to the drawing surface.
        --
        -- Args:
        -- * self: PlayerController object.
        --
        show = function(self) end,
    },
}
--]]

return PlayerCtrlInterface
