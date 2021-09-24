-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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
local QueryTemplate = require("lua/apps/query/QueryTemplate")
local UsagesOfQuery = require("lua/query/UsagesOfQuery")

-- QueryTemplate[]. The ordered list of templates displayed by the TemplateSelectWindow.
--
local QueryTemplates = ErrorOnInvalidRead.new{
    -- Query to see how to craft a given set of intermediates.
    QueryTemplate.new{
        caption = {"dana.apps.query.templateSelectWindow.howToMake"},
        query = HowToMakeQuery.new{
            selectionParams = {
                enableBoilers = true,
                enableFuels = true,
                enableRecipes = true,
            },
            sinkParams = {
                filterNormal = true,
                filterRecursive = true,
                indirectThreshold = 64,
            },
        },
        useEditor = true,
    },

    -- Query to see what can be crafted from a given set of intermediates.
    QueryTemplate.new{
        caption = {"dana.apps.query.templateSelectWindow.usagesOf"},
        query = UsagesOfQuery.new{
            selectionParams = {
                enableBoilers = true,
                enableFuels = true,
                enableRecipes = true,
            },
            sinkParams = {
                filterNormal = true,
                filterRecursive = true,
                indirectThreshold = 64,
            },
        },
        useEditor = true,
    },
}

return QueryTemplates
