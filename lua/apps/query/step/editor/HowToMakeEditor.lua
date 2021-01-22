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

local AbstractQueryEditor = require("lua/apps/query/step/editor/AbstractQueryEditor")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local MetaUtils = require("lua/class/MetaUtils")
local MinDistEditor = require("lua/apps/query/params/MinDistEditor")

local super = AbstractQueryEditor.Metatable.__index

local Metatable
local QueryType

-- Query editor for the HowToMakeQuery class.
--
-- Inherits from AbstractQueryEditor.
--
-- RO Fields:
-- * paramsEditor: MinDistEditor object editing the destParams.
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
        AbstractQueryEditor.make(object, Metatable, QueryType)
        object:setParamsEditor("HowToMakeParams")
        return object
    end,

    -- Restores the metatable of an HowToMakeEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractQueryEditor.setmetatable(object, Metatable)
    end,
}

-- Metatable of the HowToMakeEditor class.
Metatable = MetaUtils.derive(AbstractQueryEditor.Metatable, {
    __index = {
        -- Overrides AbstractQueryEditor:makeParamsEditor().
        makeParamsEditor = function(self, name)
            local result
            if name == "HowToMakeParams" then
                result = MinDistEditor.new{
                    appResources = self.appInterface.appResources,
                    isForward = false,
                    params = self.query.destParams,
                }
            else
                result = super.makeParamsEditor(self, name)
            end
            return result
        end,
    },
})

-- Type of query handled by this editor.
QueryType = "HowToMakeQuery"

AbstractQueryEditor.Factory:registerClass(QueryType, HowToMakeEditor)
return HowToMakeEditor
