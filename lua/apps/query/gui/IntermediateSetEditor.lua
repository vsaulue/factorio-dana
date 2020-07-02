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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local ReversibleArray = require("lua/containers/ReversibleArray")

local cLogger = ClassLogger.new{className = "IntermediateSetEditor"}

local AddElemButton
local addIntermediate
local ElemTypeToLabelCaption
local makeAddElemFlow

-- GUI to edit a set of Intermediate.
--
-- RO Fields:
-- * addFluidButton: AddElemButton object to add fluid intermediates.
-- * addItemButton: AddElemButton object to add item intermediates.
-- * force: IntermediateDatabase containing the Intermediate objects to use.
-- * output: Set of Intermediate object to fill.
-- * parent: LuaGuiElement in which this GUI will be created.
-- * selectedIntermediates: ReversibleArray containing the selected source intermediates.
-- * selectionFlow: LuaGuiElement displaying the set of selected source intermediates.
--
local IntermediateSetEditor = ErrorOnInvalidRead.new{
    -- Creates a new IntermediateSetEditor object.
    --
    -- Args:
    -- * object: Table to turn into a IntermediateSetEditor object (required fields: force, parent, output).
    --
    -- Returns: The argument turned into an IntermediateSetEditor object.
    --
    new = function(object)
        cLogger:assertField(object, "output")
        cLogger:assertField(object, "force")
        local parent = cLogger:assertField(object, "parent")

        ErrorOnInvalidRead.setmetatable(object)

        local mainFlow = parent.add{
            type = "flow",
            direction = "vertical",
        }
        object.addItemButton = makeAddElemFlow(object, mainFlow, "item")
        object.addFluidButton = makeAddElemFlow(object, mainFlow, "fluid")
        object.selectedIntermediates = ReversibleArray.new()
        object.selectionFlow = mainFlow.add{
            type = "flow",
            direction = "vertical",
        }
        return object
    end,

    -- Restores the metatable of a IntermediateSetEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        ErrorOnInvalidRead.setmetatable(object)
        AddElemButton.setmetatable(object.addItemButton)
        AddElemButton.setmetatable(object.addFluidButton)
        ReversibleArray.setmetatable(object.selectedIntermediates)
    end,
}

-- Button to add an item/fluid to the set of source intermediates.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * setEditor: IntermediateSetEditor owning this button.
--
AddElemButton = GuiElement.newSubclass{
    className = "IntermediateSetEditor/AddElemButton",
    mandatoryFields = {"setEditor"},
    __index = {
        onElemChanged = function(self, event)
            local intermediates = self.setEditor.force.prototypes.intermediates
            local intermediate = intermediates[self.rawElement.elem_type][self.rawElement.elem_value]
            addIntermediate(self.setEditor, intermediate)
            self.rawElement.elem_value = nil
        end,
    },
}

-- Adds an intermediate to the set of source intermediates of this filter.
--
-- Args:
-- * self: IntermediateSetEditor object.
-- * intermediate: Intermediate to add to the source set of the filter.
--
addIntermediate = function(self, intermediate)
    self.output[intermediate] = true

    local index = rawget(self.selectedIntermediates.reverse, intermediate)
    if not index then
        self.selectedIntermediates:pushBack(intermediate)
        self.selectionFlow.add{
            type = "sprite",
            sprite = intermediate.spritePath,
            tooltip = intermediate.localisedName,
        }
    end
end

-- Map[string] -> localised_string: gives the caption of the label for an AddElemButton.
ElemTypeToLabelCaption = ErrorOnInvalidRead.new{
    fluid = {"dana.apps.query.intermediateSetEditor.addFluid"},
    item = {"dana.apps.query.intermediateSetEditor.addItem"},
}

-- Adds an AddElemButton in the GUI to select a type of intermediates.
--
-- Args:
-- * self: IntermediateSetEditor object.
-- * parent: LuaGuiElement in which the button should be created.
-- * elemType: type of intermediate to select with this button (item or fluid).
--
-- Returns: The new AddElemButton object.
--
makeAddElemFlow = function(self, parent, elemType)
    local elemFlow = parent.add{
        type = "flow",
        direction = "horizontal",
    }

    -- Label
    local labelFlow = elemFlow.add{
        type = "flow",
        direction = "vertical",
    }
    local pusher1 = labelFlow.add{
        type = "empty-widget",
        style = "draggable_space_with_no_left_margin",
    }
    pusher1.style.vertically_stretchable = true
    local label = labelFlow.add{
        type = "label",
        caption = ElemTypeToLabelCaption[elemType],
    }
    label.style.vertical_align = "center"
    local pusher2 = labelFlow.add{
        type = "empty-widget",
        style = "draggable_space_with_no_left_margin",
    }
    pusher2.style.vertically_stretchable = true

    -- Elem button
    return AddElemButton.new{
        setEditor = self,
        rawElement = elemFlow.add{
            type = "choose-elem-button",
            elem_type = elemType,
        }
    }
end

return IntermediateSetEditor
