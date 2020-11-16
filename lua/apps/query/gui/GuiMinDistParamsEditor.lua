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

local cLogger = ClassLogger.new{className = "GuiMinDistParamsEditor"}

local AllowCheckbox
local changeDepth
local DepthCheckbox
local DepthField
local LocalisedStrings
local Metatable

-- Instanciated GUI of an GuiMinDistParamsEditor.
--
-- RO Fields:
-- * controller: MinDistParamsEditor. Controller owning this GUI.
-- * mainFlow: LuaGuiElement. Top-level flow owned by this GUI.
-- * parent: LuaGuiElement. Element containing this GUI.
--
local GuiMinDistParamsEditor = ErrorOnInvalidRead.new{
    -- Creates a new GuiMinDistParamsEditor object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: The argument turned into a GuiMinDistParamsEditor class.
    --
    new = function(object)
        local controller = cLogger:assertField(object, "controller")
        local parent = cLogger:assertField(object, "parent")
        localisedStrings = LocalisedStrings[controller.isForward]

        local mainFlow = parent.add{
            type = "flow",
            direction = "vertical",
        }
        object.mainFlow = mainFlow

        -- Set selector.
        mainFlow.add{
            type = "label",
            caption = localisedStrings.intermediateSetTitle,
            style = "frame_title",
        }
        controller.setEditor:open(mainFlow)
        ----------------
        mainFlow.add{
            type = "line",
            direction = "horizontal",
        }
        mainFlow.add{
            type = "label",
            caption = {"dana.apps.query.minDistParamsEditor.otherOptions"},
            style = "frame_title",
        }
        -- Allow other ingredients.
        object.allowOtherCheckbox = AllowCheckbox.new{
            field = "allowOtherIntermediates",
            gui = object,
            rawElement = mainFlow.add{
                type = "checkbox",
                caption = localisedStrings.allowOtherIntermediates,
                state = controller.params.allowOtherIntermediates,
            },
        }
        -- Maximum depth
        local depthFlow = mainFlow.add{
            type = "flow",
            direction = "horizontal",
        }
        object.depthCheckbox = DepthCheckbox.new{
            paramsEditor = object,
            gui = object,
            rawElement = GuiAlign.makeVerticallyCentered(depthFlow, {
                type = "checkbox",
                caption = {"dana.apps.query.minDistParamsEditor.maxDepth"},
                state = false,
            }),
        }
        object.depthField = DepthField.new{
            paramsEditor = object,
            gui = object,
            rawElement = depthFlow.add{
                type = "textfield",
                allow_negative = false,
                numeric = true,
                style = "short_number_textfield",
                text = "1",
            },
        }
        setmetatable(object, Metatable)
        object:setDepth(rawget(controller.params, "maxDepth"))
        return object
    end,

    -- Restores the metatable of a GuiMinDistParamsEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
        AllowCheckbox.setmetatable(object.allowOtherCheckbox)
        DepthCheckbox.setmetatable(object.depthCheckbox)
        DepthField.setmetatable(object.depthField)
    end,
}

-- Metatable of the GuiMinDistParamsEditor class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        close = function(self)
            GuiElement.safeDestroy(self.mainFlow)
            self.allowOtherCheckbox:close()
            self.depthCheckbox:close()
            self.depthField:close()
        end,

        -- Checks the "Allow other intermediates" box.
        --
        -- Args:
        -- * self: GuiMinDistParamsEditor.
        -- * value: boolean. New checked state.
        --
        setAllowOther = function(self, value)
            self.allowOtherCheckbox.rawElement.state = value
        end,

        -- Updates the depth checkbox & field.
        --
        -- Args:
        -- * self: GuiMinDistParamsEditor.
        -- * value: int or nil. The new depth value.
        --
        setDepth = function(self, value)
            local rawDepthField = self.depthField.rawElement
            if value then
                rawDepthField.text = tostring(value)
                rawDepthField.enabled = true
                self.depthCheckbox.rawElement.state = true
            else
                self.depthCheckbox.rawElement.state = false
                rawDepthField.enabled = false
            end
        end,
    },
}

-- Checkbox to enable the allowOther parameter.
--
-- RO Fields:
-- * gui: GuiMinDistParamsEditor. Owner of this element.
--
AllowCheckbox = GuiElement.newSubclass{
    className = "GuiMinDistParamsEditor/AllowCheckbox",
    mandatoryFields = {"gui"},
    __index = {
        onCheckedStateChanged = function(self, event)
            self.gui.controller:setAllowOther(event.element.state)
        end,
    }
}

-- Updates the GUI elements associated to the maxDepth parameter.
--
-- Args:
-- * self: GuiMinDistParamsEditor.
--
changeDepth = function(self)
    local enabled = self.depthCheckbox.rawElement.state
    local value = nil
    if enabled then
        value = tonumber(self.depthField.rawElement.text)
    end
    self.controller:setDepth(value)
end

-- Checkbox to enable the maxDepth parameter.
--
-- RO Fields:
-- * gui: GuiMinDistParamsEditor. Owner of this element.
--
DepthCheckbox = GuiElement.newSubclass{
    className = "GuiMinDistParamsEditor/DepthCheckbox",
    mandatoryFields = {"gui"},
    __index = {
        onCheckedStateChanged = function(self, event)
            changeDepth(self.gui)
        end,
    },
}

-- Textfield to set the maxDepth value.
--
-- RO Fields:
-- * gui: GuiMinDistParamsEditor. Owner of this element.
--
DepthField = GuiElement.newSubclass{
    className = "GuiMinDistParamsEditor/DepthField",
    mandatoryFields = {"gui"},
    __index = {
        onTextChanged = function(self, event)
            changeDepth(self.gui)
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
    return {"dana.apps.query.minDistParamsEditor." .. suffix}
end

-- Map[isForward] -> Map of localised string records.
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

return GuiMinDistParamsEditor