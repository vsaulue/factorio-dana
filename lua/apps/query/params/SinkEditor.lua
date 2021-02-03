-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local AbstractParamsEditor = require("lua/apps/query/params/AbstractParamsEditor")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiSinkEditor = require("lua/apps/query/params/GuiSinkEditor")
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "SinkEditor"}

local EditorName
local Metatable

-- TODO
--
-- RO Fields:
-- * appResources: AppResources. Resources of the application owning this controller.
-- * params: SinkParams. Parameters to edit.
--
local SinkEditor = ErrorOnInvalidRead.new{
    -- Creates a new SinkEditor object.
    --
    -- Args:
    -- * object: table. Required fields: appResources, params.
    --
    -- Returns: SinkEditor. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertField(object, "appResources")
        cLogger:assertField(object, "params")
        object.editorName = EditorName
        AbstractParamsEditor.new(object, Metatable)
        return object
    end,

    -- Restores the metatable of a SinkEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractParamsEditor.setmetatable(object, Metatable, GuiSinkEditor.setmetatable)
    end,
}

-- Metatable of the SinkEditor class.
Metatable = MetaUtils.derive(AbstractParamsEditor.Metatable, {
    __index = {
        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.appResources
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiSinkEditor.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Sets the `filterNormal` field of the params.
        --
        -- Args:
        -- * self: SinkEditor.
        -- * value: boolean. New value of `self.params.filterNormal`.
        --
        setFilterNormal = function(self, value)
            self.params.filterNormal = not not value

            local gui = rawget(self, "gui")
            if gui then
                gui:updateFilterNormal()
            end
        end,

        -- Sets the `filterRecursive` field of the params.
        --
        -- Args:
        -- * self: SinkEditor.
        -- * value: boolean. New value of `self.params.filterRecursive`.
        --
        setFilterRecursive = function(self, value)
            self.params.filterRecursive = not not value

            local gui = rawget(self, "gui")
            if gui then
                gui:updateFilterRecursive()
            end
        end,

        -- Sets the `indirectThreshold` field of the params.
        --
        -- Args:
        -- * self: SinkEditor.
        -- * value: int. New value of `self.params.indirectThreshold`.
        --
        setIndirectThreshold = function(self, value)
            self.params.indirectThreshold = value

            local gui = rawget(self, "gui")
            if gui then
                gui:updateIndirectThreshold()
            end
        end,
    },
})

-- Class identifier (value of the editorName field).
EditorName = "SinkEditor"

AbstractParamsEditor.Factory:registerClass(EditorName, SinkEditor)
return SinkEditor
