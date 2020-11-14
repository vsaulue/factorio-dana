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
local AbstractFactory = require("lua/AbstractFactory")
local ClassLogger = require("lua/logger/ClassLogger")
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiAbstractQueryEditor = require("lua/apps/query/editor/GuiAbstractQueryEditor")
local MetaUtils = require("lua/class/MetaUtils")

local cLogger = ClassLogger.new{className = "AbstractQueryEditor"}
local super = AbstractGuiController.Metatable.__index

local Metatable

-- Class used to generate a GUI to edit an AbstractQuery.
--
-- RO Fields:
-- * appResources: AppResources object of the owning application.
-- * query: The edited AbstractQuery.
-- * paramsEditor (optional): AbstractGuiController.
--
local AbstractQueryEditor = ErrorOnInvalidRead.new{
    -- Factory instance able to restore metatables of AbstractQueryEditor objects.
    Factory = AbstractFactory.new{
        enableMake = true,

        getClassNameOfObject = function(object)
            return object.query.queryType
        end,
    },

    -- Creates a new AbstractQueryEditor object.
    --
    -- Args:
    -- * object: table.
    -- * queryType: Expected value at `self.query.queryType`.
    --
    -- Returns: AbstractQueryEditor. The `object` argument.
    --
    make = function(object, queryType)
        cLogger:assertField(object, "appResources")

        local query = cLogger:assertField(object, "query")
        if query.queryType ~= queryType then
            cLogger:error("Invalid filter type (found: " .. query.queryType .. ", expected: " .. queryType .. ").")
        end
        return AbstractGuiController.new(object, Metatable)
    end,

    -- Restores the metatable of a AbstractQueryEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        MetaUtils.safeSetField(object, "gui", GuiAbstractQueryEditor.setmetatable)
    end,
}

-- Metatable of the AbstractQueryEditor class.
Metatable = {
    __index = {
        -- Implements AbstractGuiController:close().
        close = function(self)
            super.close(self)
            Closeable.safeClose(rawget(self, "paramsEditor"))
        end,

        -- Implements AbstractGuiController:makeGui().
        makeGui = function(self, parent)
            return GuiAbstractQueryEditor.new{
                controller = self,
                parent = parent,
            }
        end,
    },
}
setmetatable(Metatable.__index, {__index = super})

return AbstractQueryEditor
