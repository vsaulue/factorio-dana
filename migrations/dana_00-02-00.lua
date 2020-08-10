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

-- All these functions must work on a v0.1.1 Dana install, so they can't use code from the lua/ folder
-- (which may work only on a single future version).
local closeApp
local closeAppController
local closeCanvas
local closeDana
local closePlayer
local closePositionController
local destroyGuiElement

-- Releases API resources of an AbstractApp object.
--
-- Args:
-- * app: AbstractApp object to close.
--
closeApp = function(app)
    local appName = app.appName
    if appName == "graph" then
        app.guiSelection.frame.destroy()
    else
        assert(appName == "query")
        local stack = app.stepWindows
        for index=stack.topIndex,1,-1 do
            stack[index].frame.destroy()
        end
    end
end

-- Releases API resources of an AppController object.
--
-- Args:
-- * appController: AppController object to close.
--
closeAppController = function(appController)
    closeApp(appController.app)
    closePositionController(appController.appResources.positionController)
end

-- Releases API resources of a Dana object.
--
-- Args:
-- * dana: Dana object to close.
--
closeDana = function(dana)
    for _,player in pairs(dana.players) do
        closePlayer(player)
    end
    game.delete_surface(dana.graphSurface)
end

-- Releases API resources of a Player object.
--
-- Args:
-- * player: Player object to close.
--
closePlayer = function(player)
    closeAppController(player.appController)
    player.showButton.rawElement.destroy()
    player.menuFrame.destroy()
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
Updater.run("0.1.1", "0.2.0", function()
    -- Clean-up.
    rendering.clear(script.mod_name)
    closeDana(global.Dana)
    global.Dana = nil
    global.guiElementMap = nil
    -- Reinstall.
    EventController.on_init()
end)