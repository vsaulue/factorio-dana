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
local AbstractParamsEditor = require("lua/apps/query/gui/AbstractParamsEditor")
local ClassLogger = require("lua/logger/ClassLogger")
local CtrlIntermediateSetEditor = require("lua/apps/query/gui/CtrlIntermediateSetEditor")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiMinDistParamsEditor = require("lua/apps/query/gui/GuiMinDistParamsEditor")

local cLogger = ClassLogger.new{className = "MinDistParamsEditor"}
local super = AbstractGuiController.Metatable.__index

local Metatable

-- Editor for the MinDistParams class.
--
-- Inherits from:
-- * AbstractGuiController
-- * AbstractParamsEditor
--
-- RO Fields:
-- * appResources: AppResources. Resources of the application owning this controller.
-- * isForward: True to configure this editor for forward parsing (= looking for products).
--              False to look for ingredients.
-- * params: MinDistParams. Parameters to edit.
-- * setEditor: CtrlIntermediateSetEditor object used on the source set.
-- + AbstractGuiController
--
local MinDistParamsEditor = ErrorOnInvalidRead.new{
    -- Creates a new MinDistParamsEditor object.
    --
    -- Args:
    -- * object: table. Required fields: appResources, isForward, params.
    --
    -- Returns: The argument turned into a MinDistParamsEditor object.
    --
    new = function(object)
        AbstractParamsEditor.new(object)
        AbstractGuiController.new(object, Metatable)
        cLogger:assertField(object, "isForward")
        object.setEditor = CtrlIntermediateSetEditor.new{
            force = object.appResources.force,
            output = object.params.intermediateSet,
        }
        return object
    end,

    -- Restores the metatable of a MinDistParamsEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiMinDistParamsEditor.setmetatable)
        CtrlIntermediateSetEditor.setmetatable(object.setEditor)
    end,
}

-- Metatable of the MinDistParamsEditor class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Overrides AbstractGuiController:close().
        close = function(self)
            super.close(self)
            self.setEditor:close()
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiMinDistParamsEditor.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Sets the "allowOtherIntermediates" value in params.
        --
        -- Args:
        -- * self: MinDistParamsEditor.
        -- * value: boolean. New value.
        --
        setAllowOther = function(self, value)
            self.params.allowOtherIntermediates = value

            local gui = rawget(self, "gui")
            if gui then
                gui:setAllowOther(value)
            end
        end,

        -- Sets the "maxDepth" value in params.
        --
        -- Args:
        -- * self: MinDistParamsEditor.
        -- * value: int or nil. New value.
        --
        setDepth = function(self, value)
            self.params.maxDepth = value

            local gui = rawget(self, "gui")
            if gui then
                gui:setDepth(value)
            end
        end,
    }
}
setmetatable(Metatable.__index, {__index = super})

return MinDistParamsEditor
