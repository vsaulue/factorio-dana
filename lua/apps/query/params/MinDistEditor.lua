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
local GuiMinDistEditor = require("lua/apps/query/params/GuiMinDistEditor")
local IntermediateSetEditor = require("lua/apps/query/params/IntermediateSetEditor")

local cLogger = ClassLogger.new{className = "MinDistParamsEditor"}
local super = AbstractGuiController.Metatable.__index

local Metatable

-- Editor for the MinDistParams class.
--
-- Inherits from:
-- * AbstractGuiController
--
-- RO Fields:
-- * appResources: AppResources. Resources of the application owning this controller.
-- * isForward: True to configure this editor for forward parsing (= looking for products).
--              False to look for ingredients.
-- * params: MinDistParams. Parameters to edit.
-- * setEditor: IntermediateSetEditor object used on the source set.
-- + AbstractGuiController
--
local MinDistEditor = ErrorOnInvalidRead.new{
    -- Creates a new MinDistEditor object.
    --
    -- Args:
    -- * object: table. Required fields: appResources, isForward, params.
    --
    -- Returns: The argument turned into a MinDistEditor object.
    --
    new = function(object)
        AbstractGuiController.new(object, Metatable)
        cLogger:assertField(object, "appResources")
        cLogger:assertField(object, "isForward")
        cLogger:assertField(object, "params")
        object.setEditor = IntermediateSetEditor.new{
            appResources = object.appResources,
            output = object.params.intermediateSet,
        }
        return object
    end,

    -- Restores the metatable of a MinDistEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGuiController.setmetatable(object, Metatable, GuiMinDistEditor.setmetatable)
        IntermediateSetEditor.setmetatable(object.setEditor)
    end,
}

-- Metatable of the MinDistEditor class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Overrides AbstractGuiController:close().
        close = function(self)
            super.close(self)
            self.setEditor:close()
        end,

        -- Implements AbstractGuiController:getGuiUpcalls().
        getGuiUpcalls = function(self)
            return self.appResources
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiMinDistEditor.new{
                controller = self,
                parent = parent,
            }
        end,

        -- Sets the "allowOtherIntermediates" value in params.
        --
        -- Args:
        -- * self: MinDistEditor.
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
        -- * self: MinDistEditor.
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

return MinDistEditor
