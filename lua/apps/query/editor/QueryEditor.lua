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

-- Importing all AbstractQueryEditor to populate its Factory.
require("lua/apps/query/editor/HowToMakeEditor")
require("lua/apps/query/editor/CtrlUsagesOfEditor")

-- Wrapper of AbstractQueryEditor's factory.
local QueryEditor = ErrorOnInvalidRead.new{
    -- Creates a new AbstractQueryEditor object.
    --
    -- Args:
    -- * object: table. Required fields: app, query.
    --
    -- Returns: AbstractQueryEditor. The `object` argument converted into the desired type.
    --
    new = function(object)
        return AbstractQueryEditor.Factory:make(object)
    end,

    -- Restores the metatable of an GuiAbstractQueryEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractQueryEditor.Factory:restoreMetatable(object)
    end,
}

return QueryEditor
