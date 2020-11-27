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

local AbstractGui = require("lua/gui/AbstractGui")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local MetaUtils = require("lua/class/MetaUtils")

local Metatable

-- GUI elements of a TreeBox object.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller (override): TreeBox.
-- * flow: LuaGuiElement. Top-level GUI element containing all the nodes.
-- + AbstractGui.
--
local GuiTreeBox = ErrorOnInvalidRead.new{
    -- Creates a new GuiTreeBox object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiTreeBox. The `object` argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)
        object.flow = object.parent.add{
            type = "flow",
            direction = "vertical",
        }
        object.flow.style.vertical_spacing = 0

        local roots = object.controller.roots
        for i=1,roots.count do
            roots[i]:open(object.flow)
        end

        return object
    end,

    -- Restores the metatable of an GuiTreeBox object, and all its owned objects.
    --
    -- Args:
    -- * object: Table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
    end,
}

-- Metatable of the GuiTreeBox object.
Metatable = {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.flow)
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.flow.valid
        end,
    },
}
MetaUtils.derive(AbstractGui.Metatable, Metatable)

return GuiTreeBox
