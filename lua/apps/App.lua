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

local AbstractApp = require("lua/apps/AbstractApp")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

-- Require all apps here, so that AbstractApp.Factory gets properly initialized.
local GraphApp = require("lua/apps/graph/GraphApp")
local QueryApp = require("lua/apps/query/QueryApp")

-- Wrapper of AbstractApp's factory.
--
-- Static fields:
-- * new: function(table) -> table.
-- * setmetatable: function(table).
--
local App = AbstractApp.Factory:makeClassTable()

return App
