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

-- Query editor for the UsagesOfQuery class.
--
-- Inherits from AbstractCtrlQueryEditor.
--
-- RO Fields:
-- * paramsEditor: CtrlMinDistParamsEditor object editing the sourceParams.
--
local CtrlUsagesOfEditor = ErrorOnInvalidRead.new{
    -- Creates a new CtrlUsagesOfEditor object.
    --
    -- Args:
    -- * object: Table to turn into a CtrlUsagesOfEditor object.
    --
    -- Returns: The argument turned into a CtrlUsagesOfEditor object.
    --
    new = function(object)
        AbstractCtrlQueryEditor.make(object, QueryType)
        object.paramsEditor = CtrlMinDistParamsEditor.new{
            appResources = object.appResources,
            isForward = true,
            params = object.query.sourceParams,
        }
        return object
    end,

    -- Restores the metatable of an CtrlUsagesOfEditor object, and all its owned objects.
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
QueryType = "UsagesOfQuery"

AbstractCtrlQueryEditor.Factory:registerClass(QueryType, CtrlUsagesOfEditor)
return CtrlUsagesOfEditor