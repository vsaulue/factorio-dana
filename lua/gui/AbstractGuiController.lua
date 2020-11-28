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
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "AbstractGuiController"}

-- Class for GUI controllers.
--
-- Implements Closeable.
--
-- RO Fields:
-- * gui (optional): Closeable. Instanciated GUI of this controller.
--
local AbstractGuiController = ErrorOnInvalidRead.new{
    -- Creates a new AbstractGuiController object.
    --
    -- Args:
    -- object: table. Required field: makeGui.
    -- metatable: table. Metatable to set.
    --
    -- Returns: The argument turned into an AbstractGuiController object.
    --
    new = function(object, metatable)
        setmetatable(object, metatable)
        cLogger:assertField(object, "getGuiUpcalls")
        cLogger:assertField(object, "makeGui")
        return object
    end,

    -- Metatable of the AbstractGuiController.
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Implements Closeable:close().
            --
            -- Also clears the gui field.
            --
            close = function(self)
                Closeable.safeCloseField(self, "gui")
            end,

            -- Gets the GuiUpcalls object to use for this GUI.
            --
            -- Args:
            -- * self: AbstractGuiController.
            --
            -- Returns: GuiUpcalls. Callbacks available to this controller.
            --
            --[[
            getGuiUpcalls = function(self) end,
            --]]

            -- Makes the GUI of this controller.
            --
            -- Args:
            -- * self: AbstractGuiController.
            -- * parent: LuaGuiElement. Element in which this GUI will be created.
            --
            -- Returns: AbstractGuiController.
            --
            --[[
            makeGui = function(self, parent) end,
            --]]

            -- Instanciate the GUI of this controller.
            --
            -- Args:
            -- * self: AbstractGuiController.
            -- * parent: LuaGuiElement. Element in which this GUI will be created.
            --
            open = function(self, parent)
                local gui = rawget(self, "gui")
                cLogger:assert(not gui, "Attempt to make multiple GUIs.")
                self.gui = self:makeGui(parent)
            end,

            -- Rebuilds the GUI if it is in a corrupted state.
            --
            -- Args:
            -- * self: AbstractGuiController.
            -- * parent: LuaGuiElement. Element in which this GUI should be recreated.
            --
            repair = function(self, parent)
                local gui = rawget(self, "gui")
                if gui and (not gui:isValid()) then
                    self:close()
                    self:open(parent)
                end
            end,
        },
    },

    -- Restores the metatable of an AbstractGuiController object, and all its owned objects.
    --
    -- Args:
    -- * object: table. AbstractGuiController to restore.
    -- * metatable: table. Metatable to use.
    -- * guiMetatableSetter: function(table). Metatable setter of the "gui" field.
    --
    setmetatable = function(object, metatable, guiMetatableSetter)
        setmetatable(object, metatable)
        MetaUtils.safeSetField(object, "gui", guiMetatableSetter)
    end,
}

return AbstractGuiController
