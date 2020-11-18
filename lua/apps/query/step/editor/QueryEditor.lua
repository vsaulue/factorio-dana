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

local AbstractQueryEditor = require("lua/apps/query/step/editor/AbstractQueryEditor")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

-- Importing all AbstractQueryEditor to populate its Factory.
require("lua/apps/query/step/editor/HowToMakeEditor")
require("lua/apps/query/step/editor/UsagesOfEditor")

-- Wrapper of AbstractQueryEditor's factory.
--
-- Static fields:
-- * new: function(table) -> table.
-- * setmetatable: function(table).
--
local QueryEditor = AbstractQueryEditor.Factory:makeClassTable()

return QueryEditor
