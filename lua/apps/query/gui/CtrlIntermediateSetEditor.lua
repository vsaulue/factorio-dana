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
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local GuiIntermediateSetEditor = require("lua/apps/query/gui/GuiIntermediateSetEditor")
local ReversibleArray = require("lua/containers/ReversibleArray")

local cLogger = ClassLogger.new{className = "CtrlIntermediateSetEditor"}

local Metatable
local removeIntermediate

-- GUI to edit a set of Intermediate.
--
-- Inherits from AbstractGuiController.
--
-- RO Fields:
-- * force: IntermediateDatabase containing the Intermediate objects to use.
-- * output: Set of Intermediate object to fill.
-- + AbstractGuiController.
--
local CtrlIntermediateSetEditor = ErrorOnInvalidRead.new{
    -- Creates a new CtrlIntermediateSetEditor object.
    --
    -- Args:
    -- * object: Table to turn into a CtrlIntermediateSetEditor object (required fields: force, parent, output).
    --
    -- Returns: The argument turned into an CtrlIntermediateSetEditor object.
    --
    new = function(object)
        cLogger:assertField(object, "output")
        cLogger:assertField(object, "force")
        return AbstractGuiController.new(object, Metatable)
    end,

    -- Restores the metatable of a CtrlIntermediateSetEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiIntermediateSetEditor.setmetatable)
    end,
}

-- Metatable of the CtrlIntermediateSetEditor class.
Metatable = {
    __index = {
        -- Adds an intermediate to the set.
        --
        -- Args:
        -- * self: CtrlIntermediateSetEditor.
        -- * type: string. Type of the intermediate to add ("fluid" or "item").
        -- * name: string. Name of the intermediate to add.
        --
        addIntermediate = function(self, type, name)
            local intermediate = self.force.prototypes.intermediates[type][name]
            if not self.output[intermediate] then
                self.output[intermediate] = true

                local gui = rawget(self, "gui")
                if gui then
                    gui:addIntermediate(intermediate)
                end
            end
        end,

        -- Creates the GUI defined in this controller.
        --
        -- This CtrlIntermediateSetEditor must not have any GUI.
        --
        -- Args:
        -- * self: CtrlIntermediateSetEditor.
        -- * parent: LuaGuiElement. Element in which the GUI must be created.
        --
        makeGui = function(self, parent)
            return GuiIntermediateSetEditor.new{
                intermediateSetEditor = self,
                parent = parent,
            }
        end,

        -- Removes an intermediate from the set.
        --
        -- Args:
        -- * self: CtrlIntermediateSetEditor.
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

return CtrlIntermediateSetEditor
