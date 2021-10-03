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

local AbstractGui = require("lua/gui/AbstractGui")
local Closeable = require("lua/class/Closeable")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiAlign = require("lua/gui/GuiAlign")
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")
local ReversibleArray = require("lua/containers/ReversibleArray")

local AddElemButton
local destroyRemoveButton
local ElemTypeToLabelCaption
local GuiConstructorArgs
local GuiElemButtonPaddingArgs
local ItemsPerLine
local makeAddElemFlow
local makeIntermediateFrame
local Metatable
local RemoveButton

-- Instanciated GUI of an IntermediateSetEditor.
--
-- Inherits from AbstractGui.
--
-- RO Fields:
-- * controller (override): IntermediateSetEditor.
-- * addFluidButton: AddElemButton. GuiElement to add fluid intermediates.
-- * addItemButton: AddElemButton. GuiElement to add item intermediates.
-- * mainFlow: LuaGuiElement. Top-level flow of this GUI.
-- * removeButtons: Map<Intermediate,RemoveButton>. All RemoveButton objects indexed by their intermediate.
-- * selectedIntermediates: ReversibleArray<Intermediate>. Current selection of intermediates.
-- * selectionFlow: LuaGuiElement. Flow displaying the currently selected intermediates.
-- + AbstractGui.
--
local GuiIntermediateSetEditor = ErrorOnInvalidRead.new{
    -- Creates a new GuiIntermediateSetEditor object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiIntermediateSetEditor. The `object` argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)

        object.removeButtons = ErrorOnInvalidRead.new()
        object.selectedIntermediates = ReversibleArray.new()

        object.mainFlow = GuiMaker.run(object.parent, GuiConstructorArgs)
        object.selectionFlow = object.mainFlow.selectionFlow

        -- Elem buttons
        local elemButtonFlow = object.mainFlow.elemButtonFlow
        object.addItemButton = makeAddElemFlow(object, elemButtonFlow, "item")
        GuiMaker.run(elemButtonFlow, GuiElemButtonPaddingArgs)
        object.addFluidButton = makeAddElemFlow(object, elemButtonFlow, "fluid")
        GuiMaker.run(elemButtonFlow, GuiElemButtonPaddingArgs)
        object.addTechnologyButton = makeAddElemFlow(object, elemButtonFlow, "technology")

        for intermediate in pairs(object.controller.output) do
            object:addIntermediate(intermediate)
        end
        return object
    end,

    -- Restores the metatable of a GuiIntermediateSetEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        AddElemButton.setmetatable(object.addItemButton)
        AddElemButton.setmetatable(object.addFluidButton)
        AddElemButton.setmetatable(object.addTechnologyButton)
        ReversibleArray.setmetatable(object.selectedIntermediates)
        ErrorOnInvalidRead.setmetatable(object.removeButtons, nil, RemoveButton.setmetatable)
    end,
}

-- Metatable of the GuiIntermediateSetEditor class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Adds an intermediate to the set.
        --
        -- Args:
        -- * self: GuiIntermediateSetEditor.
        -- * intermediate: Intermediate. New intermediate in the set.
        --
        addIntermediate = function(self, intermediate)
            if self:sanityCheck() then
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
            end
        end,

        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.mainFlow)
            self.addItemButton:close()
            self.addFluidButton:close()
            self.addTechnologyButton:close()
            Closeable.closeMapValues(self.removeButtons)
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.mainFlow.valid
        end,

        -- Removes an intermediate from the set.
        --
        -- Args:
        -- * self: GuiIntermediateSetEditor.
        -- * intermediate: Intermediate. Removed intermediate.
        --
        removeIntermediate = function(self, intermediate)
            if self:sanityCheck() then
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
            end
        end,
    },
})

-- Button to add an item/fluid to the set of source intermediates.
--
-- Inherits from GuiElement.
--
-- RO Fields:
-- * controller: IntermediateSetEditor owning this button.
--
AddElemButton = GuiElement.newSubclass{
    className = "IntermediateSetEditor/AddElemButton",
    mandatoryFields = {"gui"},
    __index = {
        onElemChanged = function(self, event)
            local gui = self.gui
            if gui:sanityCheck() then
                local element = self.rawElement
                local elemValue = element.elem_value
                if elemValue then
                    gui.controller:addIntermediate(element.elem_type, elemValue)
                    element.elem_value = nil
                end
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
    technology = {"dana.apps.query.intermediateSetEditor.addTechnology"},
}

-- GuiMaker's arguments to build this GUI.
GuiConstructorArgs = {
    type = "flow",
    direction = "vertical",
    children = {
        {
            type = "flow",
            direction = "horizontal",
            name = "elemButtonFlow",
        },{
            type = "flow",
            direction = "vertical",
            name = "selectionFlow",
            styleModifiers = {
                minimal_width = 295,
            },
        }
    },
}

-- GuiMaker's arguments to build the padding elements between "Add" buttons.
GuiElemButtonPaddingArgs = {
    type = "empty-widget",
    style = "draggable_space_with_no_left_margin",
    styleModifiers = {
        width = 20,
    },
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
        gui = self,
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
    local sprite = GuiMaker.run(newFrame, {
        type = "sprite",
        resize_to_sprite = false,
        sprite = intermediate.spritePath,
        tooltip = intermediate.localisedName,
        styleModifiers = {
            height = 32,
            width = 32,
        },
    })
    sprite.style.right_margin = 3
    local button = RemoveButton.new{
        intermediate = intermediate,
        rawElement = newFrame.add{
            type = "button",
            caption = "x",
            style = "tool_button_red",
        },
        controller = self.controller,
    }
    self.removeButtons[intermediate] = button
    button.rawElement.style.width = 16
    button.rawElement.style.height = 32
    button.rawElement.style.padding = 0
end

-- Button to remove a specific intermediate from the selection.
RemoveButton = GuiElement.newSubclass{
    className = "IntermediateSetEditor/RemoveButton",
    mandatoryFields = {"controller", "intermediate"},
    __index = {
        onClick = function(self, event)
            self.controller:removeIntermediate(self.intermediate)
        end,
    },
}

return GuiIntermediateSetEditor
