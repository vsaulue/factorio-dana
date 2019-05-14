-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local Gui = require("lua/Gui")
local GuiElement = require("lua/GuiElement")

-- Class holding data associated to a player in this mod.
--
-- Stored in global: yes
--
-- Fields:
-- * rawPlayer: Associated LuaPlayer instance.
--
-- RO properties:
-- * gui: rawPlayer.gui wrapped in a Gui object.
--
local Player = {
    new = nil, -- implemented later

    setmetatable = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the Player class.
    Metatable = {
        __index = function(self, fieldName)
            local result = nil
            if fieldName == "gui" then
                result = Gui.new({rawGui = self.rawPlayer.gui})
            end
            return result
        end,
    },

    initGui = nil, -- implemented later

    startCallbacks = {
        index = "startButton",
        on_click = function(self, event)
            self.window.rawElement.visible = not self.window.rawElement.visible
        end,
    },
}

GuiElement.newCallbacks(Impl.startCallbacks)

-- Creates a new Player object.
--
-- Args:
-- * object: table to turn into the Player object (must have a "rawPlayer" field).
--
function Player.new(object)
    setmetatable(object, Impl.Metatable)
    Impl.initGui(object)
    return object
end

-- Assigns the metatable of Player class to the argument.
--
-- Intended to restore metatable of objects in the global table.
--
-- Args:
-- * object: Table to modify.
function Player.setmetatable(object)
    setmetatable(object, Impl.Metatable)
end


-- Initialize the GUI of a player.
--
-- Args:
-- * player: Player whose GUI will be created.
--
function Impl.initGui(player)
    local window = player.gui.center:add({
        type = "frame",
        name = "mainWindow",
        caption = "Chains",
        visible = false,
    })
    player.gui.left:add({
        type = "button",
        name = "menuButton",
        caption = "Chains",
    },{
        callbacksIndex = Impl.startCallbacks.index,
        window = window,
    })
end

return Player
