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

local cLogger = ClassLogger.new{className = "GuiUpcalls"}

-- Set of callbacks available to an AbstractGuiController.
--
local GuiUpcalls = ErrorOnInvalidRead.new{
    -- Checks that all methods are implemented.
    --
    -- Args:
    -- * object: GuiUpcalls.
    --
    checkMethods = function(object)
        cLogger:assertField(object, "notifyGuiCorrupted")
    end,
}

--[[
-- Metatable of the GuiUpcalls class.
Metatable = {
    __index = {
        -- Notifies the top-level controllers that a GUI needs to be rebuild.
        --
        -- And the engineers raised their steel pickaxes up on high, saying:
        -- "O Holy Gear Girl, please send forth the Blessed Train of Retribution upon the heathen modders
        -- who destroy other's GUIs, that with It, Thou mayest flatten these heretics during their
        -- playthroughs... in Thy mercy."
        --
        notifyGuiCorrupted = function(self) end,
    }
}
--]]

return GuiUpcalls
