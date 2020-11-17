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

local AbstractCtrlQueryEditor = require("lua/apps/query/editor/AbstractCtrlQueryEditor")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local CtrlMinDistParamsEditor = require("lua/apps/query/gui/CtrlMinDistParamsEditor")

local QueryType

-- Query editor for the HowToMakeQuery class.
--
-- Inherits from AbstractCtrlQueryEditor.
--
-- RO Fields:
-- * paramsEditor: CtrlMinDistParamsEditor object editing the destParams.
--
local CtrlHowToMakeEditor = ErrorOnInvalidRead.new{
    -- Creates a new CtrlHowToMakeEditor object.
    --
    -- Args:
    -- * object: Table to turn into a CtrlHowToMakeEditor object.
    --
    -- Returns: The argument turned into a CtrlHowToMakeEditor object.
    --
    new = function(object)
        AbstractCtrlQueryEditor.make(object, QueryType)
        object:setParamsEditor(CtrlMinDistParamsEditor.new{
            appResources = object.appResources,
            isForward = false,
            params = object.query.destParams,
        })
        return object
    end,

    -- Restores the metatable of an CtrlHowToMakeEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractCtrlQueryEditor.setmetatable(object)
        CtrlMinDistParamsEditor.setmetatable(object.paramsEditor)
    end,
}

-- Type of query handled by this editor.
QueryType = "HowToMakeQuery"

AbstractCtrlQueryEditor.Factory:registerClass(QueryType, CtrlHowToMakeEditor)
return CtrlHowToMakeEditor
