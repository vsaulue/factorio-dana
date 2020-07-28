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

local Updater = require("migrations/framework/Updater")

Updater.run("0.1.0", "0.1.1", function()
    -- Update global.guiElementMap
    local newGuiElementMap = {}
    for index in pairs(game.players) do
        newGuiElementMap[index] = {}
    end
    for index,guiElement in pairs(global.guiElementMap) do
        local playerIndex = guiElement.rawElement.player_index
        newGuiElementMap[playerIndex][index] = guiElement
    end
    global.guiElementMap = newGuiElementMap
end)
