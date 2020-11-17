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
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local ReversibleArray = require("lua/containers/ReversibleArray")

local cLogger = ClassLogger.new{className = "GuiIntermediateSetEditor"}

local AddElemButton
local destroyRemoveButton
local ElemTypeToLabelCaption
local ItemsPerLine
local makeAddElemFlow
local makeIntermediateFrame
local Metatable
local RemoveButton

-- Instanciated GUI of an IntermediateSetEditor.
--
-- RO Fields:
-- * addFluidButton: AddElemButton. GuiElement to add fluid intermediates.
-- * addItemButton: AddElemButton. GuiElement to add item intermediates.
-- * intermediateSetEditor: IntermediateSetEditor. Owner of this GUI.
-- * mainFlow: LuaGuiElement. Top-level flow of this GUI.
-- * removeButtons: Map<Intermediate,RemoveButton>. All RemoveButton objects indexed by their intermediate.
-- * parent: LuaGuiElement. Element in which this GUI is displaying.
-- * selectedIntermediates: ReversibleArray<Intermediate>. Current selection of intermediates.
-- * selectionFlow: LuaGuiElement. Flow displaying the currently selected intermediates.
--
local GuiIntermediateSetEditor = ErrorOnInvalidRead.new{
    new = function(object)
        local parent = cLogger:assertField(object, "parent")
        local controller = cLogger:assertField(object, "intermediateSetEditor")

        object.removeButtons = ErrorOnInvalidRead.new()
        object.selectedIntermediates = ReversibleArray.new()

        local mainFlow = parent.add{
            type = "flow",
            direction = "vertical",
        }
        object.mainFlow = mainFlow

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

        setmetatable(object, Metatable)
        for intermediate in pairs(controller.output) do
            object:addIntermediate(intermediate)
        end
        return object
    end,

    setmetatable = function(object)
        setmetatable(object, Metatable)
        AddElemButton.setmetatable(object.addItemButton)
        AddElemButton.setmetatable(object.addFluidButton)
        ReversibleArray.setmetatable(object.selectedIntermediates)
        ErrorOnInvalidRead.setmetatable(object.removeButtons, nil, RemoveButton.setmetatable)
    end,
}

Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Adds an intermediate to the set.
        --
        -- Args:
        -- * self: GuiIntermediateSetEditor.
        -- * intermediate: Intermediate. New intermediate in the set.
        --
        addIntermediate = function(self, intermediate)
            if not rawget(self.selectedIntermediates.reverse, intermediate) then
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
        end,

        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.mainFlow)
            self.addItemButton:close()
            self.addFluidButton:close()
            Closeable.closeMapValues(self.removeButtons)
        end,

        -- Removes an intermediate from the set.
        --
        -- Args:
        -- * self: GuiIntermediateSetEditor.
        -- * intermediate: Intermediate. Removed intermediate.
        --
        removeIntermediate = function(self, intermediate)
            local revArray = self.selectedIntermediates
            local removedIndex = rawget(revArray.reverse, intermediate)
            if removedIndex then
                local lineId = 1 + math.floor((removedIndex - 1) / ItemsPerLine)
                local columnId = 1 + (removedIndex - 1) % ItemsPerLine

                local lines = self.selectionFlow.children
                lines[lineId].children[columnId].destroy()
                for i=lineId,#lines-1 do
                    local firstLine = lines[i]
                    local secondLine = lines[i+1]

                    destroyRemoveButton(self, revArray[5*i+1])
                    secondLine.children[1].destroy()

                    makeIntermediateFrame(self, firstLine, revArray[5*i+1])
                end

                local count = revArray.count
                if count % ItemsPerLine == 1 then
                    lines[#lines].destroy()
                end

                destroyRemoveButton(self, intermediate)
                revArray:removeValue(intermediate)
            end
        end,
    },
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
            local element = self.rawElement
            local elemValue = element.elem_value
            if elemValue then
                self.setEditor:addIntermediate(element.elem_type, elemValue)
                self.rawElement.elem_value = nil
            end
        end,
    },
}

-- Deletes the RemoveButton object associated to an intermediate.
--
-- Args:
-- * self: GuiIntermediateSetEditor.
-- * intermediate: Intermediate. Intermediate to remove.
--
destroyRemoveButton = function(self, intermediate)
    local removeButtons = self.removeButtons
    removeButtons[intermediate]:close()
    removeButtons[intermediate] = nil
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
        setEditor = self.intermediateSetEditor,
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
        setEditor = self.intermediateSetEditor,
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
            self.setEditor:removeIntermediate(self.intermediate)
        end,
    },
}

return GuiIntermediateSetEditor
