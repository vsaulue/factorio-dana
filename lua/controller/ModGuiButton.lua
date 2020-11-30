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

local AbstractGuiController = require("lua/gui/AbstractGuiController")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiModGuiButton = require("lua/controller/GuiModGuiButton")
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "ModGuiButton"}

local Metatable

-- Controller for the top-left button outside Dana.
--
-- RO Fields:
-- * playerCtrlInterface: PlayerCtrlInterface. Callbacks to the upper controller owning this GUI.
--
local ModGuiButton = ErrorOnInvalidRead.new{
    -- Creates a new ModGuiButton object.
    --
    -- Args:
    -- * object: table. Required fields: playerCtrlInterface.
    --
    -- Returns: ModGuiButton. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertField(object, "playerCtrlInterface")
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a ModGuiButton, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiModGuiButton.setmetatable)
    end,
}

-- Metatable of the ModGuiButton class.
Metatable = MetaUtils.derive(AbstractGuiController.Metatable, {
    __index = {
        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.playerCtrlInterface
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiModGuiButton.new{
                controller = self,
                parent = parent,
            }
        end,
    },
})

return ModGuiButton
