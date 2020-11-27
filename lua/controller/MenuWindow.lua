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

local AbstractGuiController = require("lua/gui/AbstractGuiController")
local ClassLogger = require("lua/logger/ClassLogger")
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiMenuWindow = require("lua/controller/GuiMenuWindow")

local cLogger = ClassLogger.new{className = "MenuWindow"}
local super = AbstractGuiController.Metatable.__index

local Metatable

-- GUI controller for the top-left menu window.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * appMenu (optional): AbstractGuiController. Controller for the application flow.
-- * gui (override): GuiMenuWindow.
-- * playerCtrlInterface: PlayerCtrlInterface. Callbacks to the upper controller.
--
local MenuWindow = ErrorOnInvalidRead.new{
    -- Creates a new MenuWindow object.
    --
    -- Args:
    -- * object: table. Required field: playerCtrlInterface.
    --
    -- Returns: MenuWindow. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertField(object, "playerCtrlInterface")
        object.appMenu = nil
        setmetatable(object, Metatable)
        return AbstractGuiController.new(object, Metatable)
    end,

    -- Restores the metatable of a MenuWindow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiMenuWindow.setmetatable)
    end,
}

-- Metatable of the MenuWindow class.
Metatable = {
    __index = {
        -- Overrides AbstractGuiController:close().
        close = function(self)
            super.close(self)
            Closeable.safeClose(rawget(self, "appMenu"))
        end,

        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.playerCtrlInterface
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiMenuWindow.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Sets the appMenu field of this MenuWindow.
        --
        -- Args:
        -- * self: MenuWindow.
        -- * appMenu: AbstractGuiController or nil. The new controller.
        --
        setAppMenu = function(self, appMenu)
            Closeable.safeCloseField(self, "appMenu")
            self.appMenu = appMenu

            local gui = rawget(self, "gui")
            if gui then
                gui:updateAppMenu()
            end
        end,
    }
}
setmetatable(Metatable.__index, {__index = super})

return MenuWindow
