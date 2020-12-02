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

local EventController = require("lua/EventController")
local ModGui = require("mod-gui")
local Updater = require("migrations/framework/Updater")

local closeDana
local closeGui
local closePositionController

-- Destroys the children of a LuaGuiElement which belong to Dana.
--
-- Args:
-- * rawGuiElement: LuaGuiElement. Element whose children will be parsed.
--
clearGuiElement = function(rawGuiElement)
    for _,child in pairs(rawGuiElement.children) do
        if child.valid and child.get_mod() == script.mod_name then
            child.destroy()
        end
    end
end

-- Destroys all LuaGuiElement of this mod owned by a player.
--
-- Args:
-- * rawPlayer: LuaPlayer. Owner of the GUI to clear.
--
closeGui = function(rawPlayer)
    for _,root in pairs(rawPlayer.gui.children) do
        clearGuiElement(root)
    end
    clearGuiElement(ModGui.get_button_flow(rawPlayer))
end

-- Releases API resources of a Dana object.
--
-- Args:
-- * dana: Dana.
--
closeDana = function(dana)
    for _,player in pairs(dana.players) do
        closePositionController(player.positionController)
        closeGui(player.rawPlayer)
    end
    game.delete_surface(dana.graphSurface)
end

-- Releases API resources of a PositionController object.
--
-- Also moves the player back to the game's surface if he was in "Dana mode".
--
-- Args:
-- * positionController: PositionController.
--
closePositionController = function(positionController)
    local rawPlayer = positionController.rawPlayer
    if rawPlayer.surface == positionController.appSurface then
        local targetPosition = positionController.previousPosition
        rawPlayer.teleport(targetPosition, positionController.previousSurface)

        local newController = {
            type = positionController.previousControllerType,
        }
        if newController.type == defines.controllers.character then
            local previousCharacter = positionController.previousCharacter
            if previousCharacter.valid then
                newController.character = previousCharacter
            else
                newController.type = defines.controllers.ghost
            end
        end
        rawPlayer.set_controller(newController)
    end
end

-- Full delete & reinstall to the latest version.
Updater.run("0.2.4", "0.3.0", function()
    -- Clean-up.
    rendering.clear(script.mod_name)
    closeDana(global.Dana)
    global.Dana = nil
    global.guiElementMap = nil
    -- Reinstall.
    EventController.on_init()
end)
