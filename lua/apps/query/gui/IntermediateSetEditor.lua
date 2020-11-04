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
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local GuiIntermediateSetEditor = require("lua/apps/query/gui/GuiIntermediateSetEditor")
local ReversibleArray = require("lua/containers/ReversibleArray")

local cLogger = ClassLogger.new{className = "IntermediateSetEditor"}

local Metatable
local removeIntermediate

-- GUI to edit a set of Intermediate.
--
-- RO Fields:
-- * force: IntermediateDatabase containing the Intermediate objects to use.
-- * output: Set of Intermediate object to fill.
--
local IntermediateSetEditor = ErrorOnInvalidRead.new{
    -- Creates a new IntermediateSetEditor object.
    --
    -- Args:
    -- * object: Table to turn into a IntermediateSetEditor object (required fields: force, parent, output).
    --
    -- Returns: The argument turned into an IntermediateSetEditor object.
    --
    new = function(object)
        cLogger:assertField(object, "output")
        cLogger:assertField(object, "force")
        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of a IntermediateSetEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)

        local gui = rawget(object, "gui")
        if gui then
            GuiIntermediateSetEditor.setmetatable(gui)
        end
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
            local intermediate = self.force.prototypes.intermediates[type][name]
            if not self.output[intermediate] then
                self.output[intermediate] = true

                local gui = rawget(self, "gui")
                if gui then
                    gui:addIntermediate(intermediate)
                end
            end
        end,

        -- Implements Closeable:close().
        --
        -- Resets the `gui` field to nil.
        --
        close = function(self)
            Closeable.safeCloseField(self, "gui")
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
            local gui = rawget(self, "gui")
            cLogger:assert(not gui, "Attempt to make multiple GUIs.")

            self.gui = GuiIntermediateSetEditor.new{
                intermediateSetEditor = self,
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

return IntermediateSetEditor
