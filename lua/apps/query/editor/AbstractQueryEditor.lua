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

local AbstractFactory = require("lua/AbstractFactory")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "AbstractQueryEditor"}

-- Class used to generate a GUI to edit an AbstractQuery.
--
-- RO Fields:
-- * appResources: AppResources object of the owning application.
-- * query: The edited AbstractQuery.
-- * root: LuaGuiElement in which the GUI will be created.
--
local AbstractQueryEditor = ErrorOnInvalidRead.new{
    -- Checks that the mandatory fields are correctly set.
    --
    -- Args:
    -- * self: AbstractQueryEditor object.
    -- * queryType: Expected value at `self.query.queryType`.
    --
    check = function(self, queryType)
        cLogger:assertField(self, "appResources")
        cLogger:assertField(self, "root")

        local query = cLogger:assertField(self, "query")
        if query.queryType ~= queryType then
            cLogger:error("Invalid filter type (found: " .. query.queryType .. ", expected: " .. queryType .. ").")
        end
    end,

    -- Factory instance able to restore metatables of AbstractQueryEditor objects.
    Factory = AbstractFactory.new{
        enableMake = true,

        getClassNameOfObject = function(object)
            return object.query.queryType
        end,
    },
}

return AbstractQueryEditor
