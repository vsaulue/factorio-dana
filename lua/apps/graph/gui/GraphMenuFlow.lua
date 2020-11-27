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
local GuiGraphMenuFlow = require("lua/apps/graph/gui/GuiGraphMenuFlow")

local cLogger = ClassLogger.new{className = "GraphMenuFlow"}

local Metatable

-- Controller for the menu elements of a GraphApp.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * appInterface: GraphAppInterface. Callbacks to the owning app.
-- * gui: GuiGraphMenuFlow.
--
local GraphMenuFlow = ErrorOnInvalidRead.new{
    -- Creates a new GraphMenuFlow object.
    --
    -- Args:
    -- * object: table. Required fields: appInterface.
    --
    -- Returns: GraphMenuFlow. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assert(object, "appInterface")
        return AbstractGuiController.new(object, Metatable)
    end,

    -- Restores the metatable of a GraphMenuFlow object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiGraphMenuFlow.setmetatable)
    end,
}

-- Metatable of the GraphMenuFlow class.
Metatable = {
    __index = {
        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.appInterface.appResources
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiGraphMenuFlow.new{
                controller = self,
                parent = parent,
            }
        end,
    }
}
setmetatable(Metatable.__index, {__index = AbstractGuiController.Metatable.__index})

return GraphMenuFlow
