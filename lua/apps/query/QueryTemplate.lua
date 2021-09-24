-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "QueryTemplate"}

-- Template query of the query app.
--
-- RO Fields:
-- * caption: LocalisedString. Name of this type of query.
-- * query: AbstractQuery. Query to copy when using this template.
-- * useEditor: boolean. True to open up the query in the editor, false to run it directly.
--
local QueryTemplate = ErrorOnInvalidRead.new{
    -- Creates a new QueryTemplate object.
    --
    -- Args:
    -- * object: table. Mandatory fields: all.
    --
    -- Returns: QueryTemplate. The `object` argument turned into the desired type.
    --
    new = function(object)
        cLogger:assertFieldType(object, "caption", "table")
        cLogger:assertFieldType(object, "query", "table")
        cLogger:assertFieldType(object, "useEditor", "boolean")
        return ErrorOnInvalidRead.new(object)
    end,
}

return QueryTemplate
