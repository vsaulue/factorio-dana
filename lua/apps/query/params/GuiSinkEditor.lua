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
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local GuiMaker = require("lua/gui/GuiMaker")
local MetaUtils = require("lua/class/MetaUtils")

local GuiConstructorArgs
local IndirectCheckbox
local IndirectField
local Metatable
local NormalCheckbox
local RecursiveCheckbox
local updateEnableIndirect
local updateIndirectValue
local updateIndirectVisible

-- TODO
--
-- RO Fields:
-- * controller (override): SinkEditor.
-- * indirectCheckbox: IndirectCheckbox. Checkbox to enable SinkParams:indirectThreshold.
-- * mainFlow: LuaGuiElement. Top-level element owned by this GUI.
-- * normalCheckbox: NormalCheckbox. Checkbox to modify SinkParams:filterNormal.
-- * recursiveCheckbox: RecursiveCheckbox. Checkbox to modify SinkParams:filterRecursive.
--
local GuiSinkEditor = ErrorOnInvalidRead.new{
    -- Creates a new GuiSinkEditor object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiSinkEditor. The `object` argument turned into the desired type.
    --
    new = function(object)
        AbstractGui.new(object, Metatable)
        object.mainFlow = GuiMaker.run(object.parent, GuiConstructorArgs)
        object.indirectCheckbox = IndirectCheckbox.new{
            gui = object,
            rawElement = object.mainFlow.indirect.thresholdFlow.indirectCheckbox,
        }
        object.indirectField = IndirectField.new{
            gui = object,
            rawElement = object.mainFlow.indirect.thresholdFlow.indirectField,
        }
        object.normalCheckbox = NormalCheckbox.new{
            controller = object.controller,
            rawElement = object.mainFlow.normalCheckbox,
        }
        object.recursiveCheckbox = RecursiveCheckbox.new{
            controller = object.controller,
            rawElement = object.mainFlow.recursiveCheckbox,
        }

        object:updateFilterNormal()
        object:updateFilterRecursive()
        object:updateIndirectThreshold()
        return object
    end,

    -- Restores the metatable of a GuiSinkEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        AbstractGui.setmetatable(object, Metatable)
        IndirectCheckbox.setmetatable(object.indirectCheckbox)
        IndirectField.setmetatable(object.indirectField)
        NormalCheckbox.setmetatable(object.normalCheckbox)
        RecursiveCheckbox.setmetatable(object.recursiveCheckbox)
    end,
}

-- Metatable of the GuiSinkEditor class.
Metatable = MetaUtils.derive(AbstractGui.Metatable, {
    __index = {
        -- Implements AbstractGui:close().
        close = function(self)
            GuiElement.safeDestroy(self.mainFlow)
            self.indirectCheckbox:close()
            self.indirectField:close()
            self.normalCheckbox:close()
            self.recursiveCheckbox:close()
        end,

        -- Implements AbstractGui:isValid().
        isValid = function(self)
            return self.mainFlow.valid
        end,

        -- Notifies this GUI that the `filterNormal` value has changed.
        --
        -- Args:
        -- * self: GuiSinkEditor.
        --
        updateFilterNormal = function(self)
            if self:sanityCheck() then
                local value = self.controller.params.filterNormal
                self.normalCheckbox.rawElement.state = value
                updateIndirectVisible(self)
            end
        end,

        -- Notifies this GUI that the `filterRecursive` value has changed.
        --
        -- Args:
        -- * self: GuiSinkEditor.
        --
        updateFilterRecursive = function(self)
            if self:sanityCheck() then
                local value = self.controller.params.filterRecursive
                self.recursiveCheckbox.rawElement.state = value
                updateIndirectVisible(self)
            end
        end,

        -- Notifies this GUI that the `indirectThreshold` value has changed.
        --
        -- Args:
        -- * self: GuiSinkEditor.
        --
        updateIndirectThreshold = function(self)
            if self:sanityCheck() then
                local value = rawget(self.controller.params, "indirectThreshold")
                self.indirectCheckbox.rawElement.state = value
                self.indirectField.rawElement.enabled = value

                local indirectField = self.indirectField.rawElement
                if value and tonumber(indirectField.text) ~= value then
                    indirectField.text = tostring(value)
                end
            end
        end,
    },
})

-- GuiMaker's arguments to build this GUI.
GuiConstructorArgs = {
    type = "flow",
    direction = "vertical",
    children = {
        {
            type = "label",
            caption = {"dana.apps.query.sinkEditor.directTitle"},
            style = "frame_title",
        },{
            type = "checkbox",
            caption = {"dana.apps.query.sinkEditor.filterNormal"},
            name = "normalCheckbox",
            state = false,
        },{
            type = "checkbox",
            caption = {"dana.apps.query.sinkEditor.filterRecursive"},
            name = "recursiveCheckbox",
            state = false,
        },{
            type = "flow",
            direction = "vertical",
            name = "indirect",
            children = {
                {
                    type = "line",
                    direction = "horizontal",
                },{
                    type = "label",
                    caption = {"dana.apps.query.sinkEditor.indirectTitle"},
                    style = "frame_title",
                },{
                    type = "flow",
                    direction = "horizontal",
                    name = "thresholdFlow",
                    children = {
                        {
                            type = "checkbox",
                            caption = {"dana.apps.query.sinkEditor.indirectThreshold"},
                            name = "indirectCheckbox",
                            state = false,
                        },{
                            type = "textfield",
                            name = "indirectField",
                            allow_negative = false,
                            numeric = true,
                            style = "short_number_textfield",
                            text = "32",
                        },
                    },
                },
            },
        },
    },
}

-- Checkbox to enable indirect sink filtering.
--
-- RO Fields:
-- * gui: GuiSinkEditor. Owner of this element.
--
IndirectCheckbox = GuiElement.newSubclass{
    className = "GuiSinkEditor/IndirectCheckbox",
    mandatoryFields = {"gui"},
    __index = {
        onCheckedStateChanged = function(self)
            updateEnableIndirect(self.gui)
        end,
    }
}

-- Field to set the indirect sink threshold.
--
-- RO Fields:
-- * gui: GuiSinkEditor. Owner of this element.
--
IndirectField = GuiElement.newSubclass{
    className = "GuiSinkEditor/IndirectField",
    mandatoryFields = {"gui"},
    __index = {
        onTextChanged = function(self)
            updateIndirectValue(self.gui)
        end,
    },
}

-- Checkbox to enable normal sink filtering.
--
-- RO Fields:
-- * gui: GuiSinkEditor. Owner of this element.
--
NormalCheckbox = GuiElement.newSubclass{
    className = "GuiSinkEditor/NormalCheckbox",
    mandatoryFields = {"controller"},
    __index = {
        onCheckedStateChanged = function(self, event)
            self.controller:setFilterNormal(event.element.state)
        end,
    },
}

-- Checkbox to enable recursive sink filtering.
--
-- RO Fields:
-- * gui: GuiSinkEditor. Owner of this element.
--
RecursiveCheckbox = GuiElement.newSubclass{
    className = "GuiSinkEditor/RecursiveCheckbox",
    mandatoryFields = {"controller"},
    __index = {
        onCheckedStateChanged = function(self, event)
            self.controller:setFilterRecursive(event.element.state)
        end,
    },
}

-- Notifies this GUI that the "enable indirect filter" box was modified.
--
-- Args:
-- * self: GuiSinkEditor.
--
updateEnableIndirect = function(self)
    if self:sanityCheck() then
        local enabled = self.indirectCheckbox.rawElement.state
        if enabled then
            local value = tonumber(self.indirectField.rawElement.text)
            if value then
                self.controller:setIndirectThreshold(value)
            else
                self.controller:setIndirectThreshold(64)
            end
        else
            self.controller:setIndirectThreshold(nil)
        end
    end
end

-- Notifies this GUI that the "indirect threshold" field was modified.
--
-- Args:
-- * self: GuiSinkEditor.
--
updateIndirectValue = function(self)
    if self:sanityCheck() then
        local value = tonumber(self.indirectField.rawElement.text)
        if value then
            self.controller:setIndirectThreshold(value)
        end
    end
end

-- Shows/hides the "indirect" section of this GUI depending in direct filters.
--
-- Args:
-- * self: GuiSinkEditor.
--
updateIndirectVisible = function(self)
    local params = self.controller.params
    self.mainFlow.indirect.visible = params.filterNormal or params.filterRecursive
end

return GuiSinkEditor
