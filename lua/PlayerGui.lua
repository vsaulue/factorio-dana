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
local GuiElement = require("lua/gui/GuiElement")

local cLogger = ClassLogger.new{className = "PlayerGui"}

local Metatable

-- GUI of a player controller (not a specific application).
--
-- RO field:
-- * player: Player object attached to this GUI.
--
local PlayerGui = ErrorOnInvalidRead.new{
    -- Creates a new PlayerGui object.
    --
    -- Args:
    -- * object: Table to turn into a PlayerGui object (required field: player).
    --
    -- Returns: The argument turned into a PlayerGui object.
    --
    new = function(object)
        local player = cLogger:assertField(object, "player")
        object.rawElement = player.rawPlayer.gui.left.add{
            type = "button",
            name = "menuButton",
            caption = "Dana",
        }
        setmetatable(object, Metatable)
        GuiElement.bind(object)
        return object
    end,

    -- Restores the metatable of a Player instance, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Callbacks for the top-left button.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements GuiElement:onClick().
        --
        onClick = function(self, event)
            self.player:toggleOpened()
        end,
    },
}

return PlayerGui
