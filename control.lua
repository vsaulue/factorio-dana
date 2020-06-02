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

local FactorioLoggerBackend = require("lua/logger/backends/FactorioLoggerBackend")
local GuiElement = require("lua/gui/GuiElement")
local Logger = require("lua/logger/Logger")
local Dana = require("lua/Dana")

Logger.init(FactorioLoggerBackend)

local dana

local function on_load()
    Logger.info("on_load() started.")

    GuiElement.on_load()

    dana = global.Dana
    Dana.setmetatable(dana)

    Logger.info("on_load() completed.")
end

local function on_init()
    Logger.info("on_init() started.")

    GuiElement.on_init()

    dana = Dana.new()
    global.Dana = dana

    Logger.info("on_init() completed.")
end

local function on_gui_click(event)
    GuiElement.on_gui_click(event)
end

local function on_player_created(event)
    dana:on_player_created(event)
end

local function on_player_selected_area(event)
    dana:on_player_selected_area(event)
end

local events = defines.events

script.on_load(on_load)
script.on_init(on_init)
script.on_event(events.on_gui_click, on_gui_click)
script.on_event(events.on_player_created, on_player_created)
script.on_event(events.on_player_selected_area, on_player_selected_area)