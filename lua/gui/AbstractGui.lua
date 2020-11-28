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

local cLogger = ClassLogger.new{className = "AbstractGui"}

-- Instanciated GUI of an AbstractGuiController.
--
-- RO Fields:
-- * controller: AbstractController. Controller owning this GUI.
-- * parent: LuaGuiElement. Element containing this GUI.
--
local AbstractGui = ErrorOnInvalidRead.new{
    Metatable = {
        __index = ErrorOnInvalidRead.new{
            -- Implements Closeable:close().
            --[[
            close = function(self) end,
            --]]

            -- Checks if this GUI is valid (= not corrupted).
            --
            -- Args:
            -- self: AbstractGui.
            --
            -- Returns: True if this GUI seems fine. False if it needs to be rebuilt.
            --
            --[[
            isValid = function(self) end,
            --]]

            -- Checks if this GUI is valid, and notify upper controllers of any corruption.
            --
            -- Args:
            -- * self: AbstractGui.
            --
            -- Returns: boolean. Same as AbstractGui:isValid().
            --
            sanityCheck = function(self)
                local isValid = self:isValid()
                if not isValid then
                    self.controller:getGuiUpcalls():notifyGuiCorrupted()
                end
                return isValid
            end,
        },
    },

    -- Creates a new AbstractGui object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    -- * metatable: table. Metatable to use.
    --
    -- Returns: AbstractGui. The `object` argument turned into the desired type.
    --
    new = function(object, metatable)
        cLogger:assertField(object, "controller")
        cLogger:assertField(object, "parent")
        setmetatable(object, metatable)
        cLogger:assertField(object, "close")
        cLogger:assertField(object, "isValid")
        return object
    end,

    -- Restores the metatable of an AbstractGuiController object, and all its owned objects.
    setmetatable = setmetatable,
}

return AbstractGui
