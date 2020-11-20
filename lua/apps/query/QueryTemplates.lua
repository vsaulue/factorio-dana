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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local HowToMakeQuery = require("lua/query/HowToMakeQuery")
local UsagesOfQuery = require("lua/query/UsagesOfQuery")

-- Map of QueryTemplate object (= preset queries), indexed by names.
--
-- RO Fields:
-- * caption: LocalisedString. Caption of the button in the TemplateSelectWindow.
-- * queryClass: table. Class table of the query.
--
local QueryTemplates = ErrorOnInvalidRead.new{
    -- Query to see how to craft a given set of intermediates.
    HowToMake = ErrorOnInvalidRead.new{
        caption = {"dana.apps.query.templateSelectWindow.howToMake"},
        queryClass = HowToMakeQuery,
    },

    -- Query to see what can be crafted from a given set of intermediates.
    UsagesOf = ErrorOnInvalidRead.new{
        caption = {"dana.apps.query.templateSelectWindow.usagesOf"},
        queryClass = UsagesOfQuery,
    },
}

return QueryTemplates
