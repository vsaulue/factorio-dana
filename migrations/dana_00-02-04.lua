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
local Updater = require("migrations/framework/Updater")

local closeDana
local closeGui
local closePositionController

-- Destroys all LuaGuiElement of this mod owned by a player.
--
-- Args:
-- * rawPlayer: LuaPlayer whose GUI will be cleared.
--
closeGui = function(rawPlayer)
    for _,rootName in ipairs{"center","left","top","screen"} do
        local rootElem = rawPlayer.gui[rootName]
        for _,child in pairs(rootElem.children) do
            if child.valid and child.get_mod() == script.mod_name then
                child.destroy()
            end
        end
    end
end

-- Releases API resources of a Dana object.
--
-- Args:
-- * dana: Dana object to close.
--
closeDana = function(dana)
    for _,player in pairs(dana.players) do
        closePositionController(player.appController.appResources.positionController)
        closeGui(player.rawPlayer)
    end
    game.delete_surface(dana.graphSurface)
end

-- Releases API resources of a PositionController object.
--
-- Also moves the player back to the game's surface if he was in "Dana mode".
--
-- Args:
-- * positionController: PositionController object to close.
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
Updater.run("0.1.0", "0.2.4", function()
    -- Clean-up.
    rendering.clear(script.mod_name)
    closeDana(global.Dana)
    global.Dana = nil
    global.guiElementMap = nil
    -- Reinstall.
    EventController.on_init()
end)
