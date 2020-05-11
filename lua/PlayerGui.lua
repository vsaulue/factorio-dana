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

local StartCallbacks

-- GUI of a player controller (not a specific application).
--
-- RO field:
-- * player: Player object attached to this GUI.
-- * previousPosition: Position of the player on the previous surface.
-- * previousSurface: LuaSurface on which the player was before opening this GUI.
--
local PlayerGui = ErrorOnInvalidRead.new{
    new = function(object)
        local player = cLogger:assertField(object, "player")
        object.callbacksIndex = StartCallbacks.index
        object.previousPosition = {0,0}
        ErrorOnInvalidRead.setmetatable(object)
        player.gui.left:add({
            type = "button",
            name = "menuButton",
            caption = "Chains",
        }, object)
        return object
    end,
}

-- Callbacks for the top-left button.
StartCallbacks = {
    index = "startButton",
    on_click = function(self, event)
        local player = self.player
        local targetPosition = self.previousPosition
        self.previousPosition = player.rawPlayer.position
        if player.opened then
            player.rawPlayer.teleport(targetPosition, self.previousSurface)
        else
            self.previousSurface = player.rawPlayer.surface
            player.rawPlayer.teleport(targetPosition, player.graphSurface)
        end
        player.opened = not player.opened
    end,
}

GuiElement.newCallbacks(StartCallbacks)

return PlayerGui
