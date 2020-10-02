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

local AbstractParamsEditor = require("lua/apps/query/gui/AbstractParamsEditor")
local CheckboxUpdater = require("lua/gui/CheckboxUpdater")
local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local IntermediateSetEditor = require("lua/apps/query/gui/IntermediateSetEditor")

local cLogger = ClassLogger.new{className = "ReachableFilterEditor"}

local DepthCheckbox
local DepthField
local LocalisedStrings

-- Filter editor for the ReachableQueryFilter class.
--
-- Inherits from AbstractParamsEditor.
--
-- RO Fields:
-- * allowOtherCheckbox: CheckboxUpdater handling the allowOtherIntermediates field.
-- * depthCheckbox: DepthCheckbox object enabling/disabling the maxDepth parameter.
-- * depthField: DepthField object setting the maxDepth value.
-- * isForward: True to configure this editor for forward parsing (= looking for products).
--              False to look for ingredients.
-- * setEditor: IntermediateSetEditor object used on the source set.
--
local ReachableFilterEditor = ErrorOnInvalidRead.new{
    -- Creates a new ReachableFilterEditor object.
    --
    -- Args:
    -- * object: Table to turn into a ReachableFilterEditor object (required fields: see AbstractParamsEditor).
    --
    -- Returns: The argument turned into a ReachableFilterEditor object.
    --
    new = function(object)
        AbstractParamsEditor.new(object)
        ErrorOnInvalidRead.setmetatable(object)
        local isForward = cLogger:assertField(object, "isForward")
        local localisedStrings = LocalisedStrings[isForward]
        -- Set selector.
        object.root.add{
            type = "label",
            caption = localisedStrings.intermediateSetTitle,
            style = "frame_title",
        }
        object.setEditor = IntermediateSetEditor.new{
            force = object.appResources.force,
            output = object.filter.intermediateSet,
            parent = object.root,
        }
        ----------------
        object.root.add{
            type = "line",
            direction = "horizontal",
        }
        object.root.add{
            type = "label",
            caption = {"dana.apps.query.reachableFilterEditor.otherOptions"},
            style = "frame_title",
        }
        -- Allow other ingredients.
        object.allowOtherCheckbox = CheckboxUpdater.new{
            object = object.filter,
            field = "allowOtherIntermediates",
            rawElement = object.root.add{
                type = "checkbox",
                caption = localisedStrings.allowOtherIntermediates,
                state = object.filter.allowOtherIntermediates,
            },
        }
        -- Maximum depth
        local depthFlow = object.root.add{
            type = "flow",
            direction = "horizontal",
        }
        object.depthCheckbox = DepthCheckbox.new{
            filterEditor = object,
            rawElement = GuiAlign.makeVerticallyCentered(depthFlow, {
                type = "checkbox",
                caption = {"dana.apps.query.reachableFilterEditor.maxDepth"},
                state = false,
            }),
        }
        object.depthField = DepthField.new{
            filterEditor = object,
            rawElement = depthFlow.add{
                type = "textfield",
                allow_negative = false,
                numeric = true,
                style = "short_number_textfield",
                text = "1",
                enabled = false,
            },
        }
        return object
    end,

    -- Restores the metatable of a ReachableFilterEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)
        IntermediateSetEditor.setmetatable(object.setEditor)
        CheckboxUpdater.setmetatable(object.allowOtherCheckbox)
        DepthCheckbox.setmetatable(object.depthCheckbox)
        DepthField.setmetatable(object.depthField)
    end,
}

-- Checkbox to enable the maxDepth parameter.
--
-- RO Fields:
-- * filterEditor: ReachableFilterEditor object owning this checkbox.
--
DepthCheckbox = GuiElement.newSubclass{
    className = "ReachableFilterEditor/DepthCheckbox",
    mandatoryFields = {"filterEditor"},
    __index = {
        onCheckedStateChanged = function(self, event)
            local state = event.element.state
            local depthField = self.filterEditor.depthField
            local filter = self.filterEditor.filter

            depthField.rawElement.enabled = state
            if state then
                filter.maxDepth = tonumber(depthField.rawElement.text)
            else
                filter.maxDepth = nil
            end
        end,
    },
}

-- Textfield to set the maxDepth value.
--
-- RO Fields:
-- * filterEditor; ReachableFilterEditor object owning this textfield.
--
DepthField = GuiElement.newSubclass{
    className = "ReachableFilterEditor/DepthField",
    mandatoryFields = {"filterEditor"},
    __index = {
        onTextChanged = function(self, event)
            self.filterEditor.filter.maxDepth = tonumber(event.element.text)
        end,
    },
}

-- Helper function to make localised strings for this editor.
--
-- Args:
-- * suffix: string to add at the end of the common path.
--
-- Returns: The generated localised string.
--
local function makeLocalisedString(suffix)
    return {"dana.apps.query.reachableFilterEditor." .. suffix}
end

-- Map[isForward] -> Map of localised string recots.
--
-- Fields (localised string record):
-- * allowOtherIntermediates: Label for the allowOtherIntermediates option.
-- * intermediateSetTitle: Label for the set selector title.
--
LocalisedStrings = ErrorOnInvalidRead.new{
    [true] = {
        allowOtherIntermediates = makeLocalisedString("forward.allowOtherIntermediates"),
        intermediateSetTitle = makeLocalisedString("forward.intermediateSetTitle"),
    },
    [false] = {
        allowOtherIntermediates = makeLocalisedString("backward.allowOtherIntermediates"),
        intermediateSetTitle = makeLocalisedString("backward.intermediateSetTitle"),
    },
}

return ReachableFilterEditor
