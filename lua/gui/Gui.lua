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

local GuiElement = require("lua/gui/GuiElement")
local Logger = require("lua/Logger")

-- Wrapper of the LuaGui class from Factorio.
--
-- Stored in global: no
--
-- Fields:
-- * rawGui: Wrapped LuaGui object.
--
-- RO properties:
-- * center/goal/left/top: fields of rawGui, wrapped in GuiElement instances.
--
local Gui = {
    new = nil, -- defined later

    -- Set of fields from rawGui that shoulf be wrapped in GuiElement.
    WrappedFields = {
        center=true,
        goal=true,
        left=true,
        top=true,
    },
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the Gui class.
    Metatable= {
        __index= nil, -- defined later
    }
}

function Impl.Metatable.__index(self, fieldName)
    local result = nil
    if self.rawGui then
        if Gui.WrappedFields[fieldName] then
            result = GuiElement.wrap(self.rawGui[fieldName])
        end
    end
    return result
end

-- Creates a new Gui object.
--
-- Args:
-- * object: table to turn into a Gui instance (must have a "rawGui" field).
--
-- Returns: The argument, turned into a Gui object.
--
function Gui.new(object)
    local result = nil
    if object.rawGui then
        setmetatable(object, Impl.Metatable)
        result = object
    else
        Logger.error("Invalid arguments to Gui.new() (missing rawGui field).")
    end
    return result
end

return Gui
