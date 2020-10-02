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
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local ReversibleArray = require("lua/containers/ReversibleArray")

local cLogger = ClassLogger.new{className = "IntermediateSetEditor"}

local AddElemButton
local addIntermediate
local ElemTypeToLabelCaption
local ItemsPerLine
local makeAddElemFlow
local makeIntermediateFrame
local RemoveButton
local removeIntermediate

-- GUI to edit a set of Intermediate.
--
-- RO Fields:
-- * addFluidButton: AddElemButton object to add fluid intermediates.
-- * addItemButton: AddElemButton object to add item intermediates.
-- * removeButtons[intermediate]: Map of RemoveButton, indexed by their intermediate field.
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
        object.removeButtons = ErrorOnInvalidRead.new()
        object.selectedIntermediates = ReversibleArray.new()

        local mainFlow = parent.add{
            type = "flow",
            direction = "vertical",
        }

        -- Elem buttons
        local elemButtonFlow = mainFlow.add{
            type = "flow",
            direction = "horizontal",
        }
        object.addItemButton = makeAddElemFlow(object, elemButtonFlow, "item")
        local pusher = elemButtonFlow.add{
            type = "empty-widget",
            style = "draggable_space_with_no_left_margin",
        }
        pusher.style.width = 20

        object.addFluidButton = makeAddElemFlow(object, elemButtonFlow, "fluid")
        -- Selection flow
        object.selectionFlow = mainFlow.add{
            type = "flow",
            direction = "vertical",
        }
        object.selectionFlow.style.minimal_width = 295

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

        ErrorOnInvalidRead.setmetatable(object.removeButtons)
        for _,removeButton in pairs(object.removeButtons) do
            RemoveButton.setmetatable(removeButton)
        end
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
            local elemValue = self.rawElement.elem_value
            if elemValue then
                local intermediates = self.setEditor.force.prototypes.intermediates
                local intermediate = intermediates[self.rawElement.elem_type][elemValue]
                addIntermediate(self.setEditor, intermediate)
                self.rawElement.elem_value = nil
            end
        end,
    },
}

-- Adds an intermediate to the set.
--
-- Args:
-- * self: IntermediateSetEditor object.
-- * intermediate: Intermediate to add.
--
addIntermediate = function(self, intermediate)
    self.output[intermediate] = true

    local index = rawget(self.selectedIntermediates.reverse, intermediate)
    if not index then
        self.selectedIntermediates:pushBack(intermediate)
        local count = self.selectedIntermediates.count
        local lineFlow
        if count % ItemsPerLine == 1 then
            lineFlow = self.selectionFlow.add{
                type = "flow",
                direction = "horizontal",
            }
        else
            local lineId = 1 + math.floor((count - 1) / ItemsPerLine)
            lineFlow = self.selectionFlow.children[lineId]
        end
        makeIntermediateFrame(self, lineFlow, intermediate)
    end
end

-- Map[string] -> localised_string: gives the caption of the label for an AddElemButton.
ElemTypeToLabelCaption = ErrorOnInvalidRead.new{
    fluid = {"dana.apps.query.intermediateSetEditor.addFluid"},
    item = {"dana.apps.query.intermediateSetEditor.addItem"},
}

-- Maximum number of items per line in the selectionFlow.
ItemsPerLine = 5

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
    GuiAlign.makeVerticallyCentered(elemFlow, {
        type = "label",
        caption = ElemTypeToLabelCaption[elemType],
    })

    -- Elem button
    return AddElemButton.new{
        setEditor = self,
        rawElement = elemFlow.add{
            type = "choose-elem-button",
            elem_type = elemType,
        }
    }
end

-- Creates the frame of a selected intermediate.
--
-- Args:
-- * self: IntermediateSetEditor object.
-- * parent: LuaGuiElement in which the frame will be created.
-- * intermediate: The selected Intermediate.
--
makeIntermediateFrame = function(self, parent, intermediate)
    local newFrame = parent.add{
        type = "frame",
        direction = "horizontal",
        style = "borderless_deep_frame",
    }
    newFrame.style.padding = 2
    local sprite = newFrame.add{
        type = "sprite",
        sprite = intermediate.spritePath,
        tooltip = intermediate.localisedName,
    }
    sprite.style.right_margin = 3
    local button = RemoveButton.new{
        intermediate = intermediate,
        rawElement = newFrame.add{
            type = "button",
            caption = "x",
            style = "tool_button_red",
        },
        setEditor = self,
    }
    self.removeButtons[intermediate] = button
    button.rawElement.style.width = 16
    button.rawElement.style.height = 32
    button.rawElement.style.padding = 0
end

-- Button to remove a specific intermediate from the selection.
RemoveButton = GuiElement.newSubclass{
    className = "IntermediateSetEditor/RemoveButton",
    mandatoryFields = {"setEditor", "intermediate"},
    __index = {
        onClick = function(self, event)
            removeIntermediate(self.setEditor, self.intermediate)
        end,
    },
}

-- Removes an intermediate from the selection.
--
-- Args:
-- * self: IntermediateSetEditor object.
-- * removedIntermediate: Intermediate to remove.
--
removeIntermediate = function(self, removedIntermediate)
    self.output[removedIntermediate] = nil
    self.removeButtons[removedIntermediate] = nil
    local removedIndex = self.selectedIntermediates:removeValue(removedIntermediate)
    local lineId = 1 + math.floor((removedIndex - 1) / ItemsPerLine)
    local columnId = 1 + (removedIndex - 1) % ItemsPerLine

    local lines = self.selectionFlow.children
    GuiElement.destroy(lines[lineId].children[columnId])
    for i=lineId,#lines-1 do
        local firstLine = lines[i]
        local secondLine = lines[i+1]
        GuiElement.destroy(secondLine.children[1])
        makeIntermediateFrame(self, firstLine, self.selectedIntermediates[5*i])
    end

    local count = self.selectedIntermediates.count
    if count % ItemsPerLine == 0 then
        GuiElement.destroy(lines[#lines])
    end
end

return IntermediateSetEditor
