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
local GuiIntermediateSetEditor = require("lua/apps/query/params/GuiIntermediateSetEditor")

local cLogger = ClassLogger.new{className = "IntermediateSetEditor"}

local Metatable

-- GUI to edit a set of Intermediate.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * appResources: AppResources. Application resources, containing the full set of intermediates.
-- * output: Set<Intermediate>. Edited set of intermediates.
-- + AbstractGuiController.
--
local IntermediateSetEditor = ErrorOnInvalidRead.new{
    -- Creates a new IntermediateSetEditor object.
    --
    -- Args:
    -- * object: table. Required fields: appResources, output).
    --
    -- Returns: The argument turned into an IntermediateSetEditor object.
    --
    new = function(object)
        cLogger:assertField(object, "appResources")
        cLogger:assertField(object, "output")
        return AbstractGuiController.new(object, Metatable)
    end,

    -- Restores the metatable of a IntermediateSetEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiIntermediateSetEditor.setmetatable)
    end,
}

-- Metatable of the IntermediateSetEditor class.
Metatable = {
    __index = {
        -- Adds an intermediate to the set.
        --
        -- Args:
        -- * self: IntermediateSetEditor.
        -- * type: string. Type of the intermediate to add ("fluid" or "item").
        -- * name: string. Name of the intermediate to add.
        --
        addIntermediate = function(self, type, name)
            local intermediate = self.appResources.force.prototypes.intermediates[type][name]
            if not self.output[intermediate] then
                self.output[intermediate] = true

                local gui = rawget(self, "gui")
                if gui then
                    gui:addIntermediate(intermediate)
                end
            end
        end,

        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.appResources
        end,

        -- Creates the GUI defined in this controller.
        --
        -- This IntermediateSetEditor must not have any GUI.
        --
        -- Args:
        -- * self: IntermediateSetEditor.
        -- * parent: LuaGuiElement. Element in which the GUI must be created.
        --
        makeGui = function(self, parent)
            return GuiIntermediateSetEditor.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Removes an intermediate from the set.
        --
        -- Args:
        -- * self: IntermediateSetEditor.
        -- * intermediate: Intermediate. Intermediate to remove.
        --
        removeIntermediate = function(self, intermediate)
            if self.output[intermediate] then
                self.output[intermediate] = nil

                local gui = rawget(self, "gui")
                if gui then
                    gui:removeIntermediate(intermediate)
                end
            end
        end,
    }
}
setmetatable(Metatable.__index, {__index = AbstractGuiController.Metatable.__index})

return IntermediateSetEditor
