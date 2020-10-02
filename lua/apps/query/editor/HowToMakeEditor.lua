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

local AbstractQueryEditor = require("lua/apps/query/editor/AbstractQueryEditor")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MinDistParamsEditor = require("lua/apps/query/gui/MinDistParamsEditor")

local QueryType

-- Query editor for the HowToMakeQuery class.
--
-- Inherits from AbstractQueryEditor.
--
-- RO Fields:
-- * paramsEditor: MinDistParamsEditor object editing the filter.
--
local HowToMakeEditor = ErrorOnInvalidRead.new{
    -- Creates a new HowToMakeEditor object.
    --
    -- Args:
    -- * object: Table to turn into a HowToMakeEditor object.
    --
    -- Returns: The argument turned into a HowToMakeEditor object.
    --
    new = function(object)
        AbstractQueryEditor.check(object, QueryType)
        ErrorOnInvalidRead.setmetatable(object)
        object.paramsEditor = MinDistParamsEditor.new{
            appResources = object.appResources,
            filter = object.query.filter,
            isForward = false,
            root = object.root,
        }
        return object
    end,

    -- Restores the metatable of an HowToMakeEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)
        MinDistParamsEditor.setmetatable(object.paramsEditor)
    end,
}

-- Type of query handled by this editor.
QueryType = "HowToMakeQuery"

AbstractQueryEditor.Factory:registerClass(QueryType, HowToMakeEditor)
return HowToMakeEditor
