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

local AbstractFilterEditor = require("lua/apps/query/gui/AbstractFilterEditor")
local CheckboxUpdater = require("lua/gui/CheckboxUpdater")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local IntermediateSetEditor = require("lua/apps/query/gui/IntermediateSetEditor")

local cLogger = ClassLogger.new{className = "ProductFilterEditor"}

-- Filter editor for the ProductQueryFilter class.
--
-- Inherits from AbstractFilterEditor.
--
-- RO Fields:
-- * allowOtherCheckbox: CheckboxUpdater handling the allowOtherIngredients field.
-- * setEditor: IntermediateSetEditor object used on the source set.
--
local ProductFilterEditor = ErrorOnInvalidRead.new{
    -- Creates a new ProductFilterEditor object.
    --
    -- Args:
    -- * object: Table to turn into a ProductFilterEditor object (required fields: see AbstractFilterEditor).
    --
    -- Returns: The argument turned into a ProductFilterEditor object.
    --
    new = function(object)
        AbstractFilterEditor.new(object)
        ErrorOnInvalidRead.setmetatable(object)
        if object.filter.filterType ~= "product" then
            cLogger:error("Invalid filter type: " .. object.filter.filterType)
        end
        object.root.add{
            type = "label",
            caption = {"dana.apps.query.productFilterEditor.sourceSetTitle"},
            style = "frame_title",
        }
        object.setEditor = IntermediateSetEditor.new{
            force = object.appResources.force,
            output = object.filter.sourceIntermediates,
            parent = object.root,
        }
        object.root.add{
            type = "line",
            direction = "horizontal",
        }
        object.root.add{
            type = "label",
            caption = {"dana.apps.query.productFilterEditor.otherOptions"},
            style = "frame_title",
        }
        object.allowOtherCheckbox = CheckboxUpdater.new{
            object = object.filter,
            field = "allowOtherIngredients",
            rawElement = object.root.add{
                type = "checkbox",
                caption = {"dana.apps.query.productFilterEditor.allowOtherIngredients"},
                state = object.filter.allowOtherIngredients,
            },
        }
        return object
    end,

    -- Restores the metatable of a ProductFilterEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)
        IntermediateSetEditor.setmetatable(object.setEditor)
        CheckboxUpdater.setmetatable(object.allowOtherCheckbox)
    end,
}

AbstractFilterEditor.Factory:registerClass("product", ProductFilterEditor)
return ProductFilterEditor
