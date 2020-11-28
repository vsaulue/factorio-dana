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

local AppTestbench = require("lua/testing/AppTestbench")
local GuiElement = require("lua/gui/GuiElement")
local IntermediateSetEditor = require("lua/apps/query/params/IntermediateSetEditor")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("IntermediateSetEditor (& GUI)", function()
    local appTestbench
    local fluids
    local items
    local parent
    setup(function()
        local rawData = {
            fluid = {
                steam = {type = "fluid", name = "steam"},
                water = {type = "fluid", name = "water"},
            },
            item = {
                coal = {type = "item", name = "coal"},
                wood = {type = "item", name = "wood"},
            },
        }
        for i=1,5 do
            local itemName = "item" .. i
            rawData.item[itemName] = {type = "item", name = itemName}
        end

        appTestbench = AppTestbench.make{
            rawData = rawData,
        }
        appTestbench:setup()

        fluids = appTestbench.prototypes.intermediates.fluid
        items = appTestbench.prototypes.intermediates.item
        parent = appTestbench.player.gui.center
    end)

    local object
    local output
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        output = {}
        for i=1,5 do
            output[items["item"..i]] = true
        end

        object = IntermediateSetEditor.new{
            appResources = appTestbench.appResources,
            output = output,
        }
    end)

    it(".new()", function()
        assert.are.same(object, {
            appResources = appTestbench.appResources,
            output = output,
        })
    end)

    describe(".setmetatable()", function()
         local runTest = function()
            SaveLoadTester.run{
                objects = {
                    appTestbench = appTestbench,
                    object = object,
                },
                metatableSetter = function(objects)
                    AppTestbench.setmetatable(objects.appTestbench)
                    IntermediateSetEditor.setmetatable(objects.object)
                end,
            }
        end

        it("-- no gui", function()
            runTest()
        end)

        it("-- with gui", function()
            object:open(parent)
            runTest()
        end)
    end)

    describe(":addIntermediate()", function()
        it("-- no GUI", function()
            object:addIntermediate("item", "coal")
            assert.is_true(output[items.coal])
        end)

        it("-- with GUI", function()
            object:open(parent)
            object:addIntermediate("fluid", "water")
            local water = fluids.water
            local intermediateFrame = object.gui.selectionFlow.children[2].children[1]
            assert.is_true(output[water])
            assert.are.equals(intermediateFrame.children[1].sprite, water.spritePath)
            assert.are.equals(object.gui.removeButtons[water].rawElement, intermediateFrame.children[2])
        end)
    end)

    describe("", function()
        before_each(function()
            object:addIntermediate("item", "coal")
            object:open(parent)
        end)

        it(":open()", function()
            assert.are.equals(object.gui.controller, object)
            assert.are.equals(object.gui.selectionFlow, parent.children[1].children[2])
        end)

        it(":close()", function()
            object:close()
            assert.is_nil(rawget(object, "gui"))
            assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
            assert.is_nil(parent.children[1])
        end)
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(appTestbench.appResources, object:getGuiUpcalls())
    end)

    it(":gui:isValid()", function()
        object:open(parent)
        local gui = object.gui
        assert.is_true(gui:isValid())
        object:close()
        assert.is_false(gui:isValid())
    end)

    describe(":removeIntermediate()", function()
        it("-- no GUI", function()
            object:removeIntermediate(items.item1)
            assert.are.same(output, {
                [items.item2] = true,
                [items.item3] = true,
                [items.item4] = true,
                [items.item5] = true,
            })
        end)

        it("-- with GUI", function()
            object:open(parent)
            object:addIntermediate("item", "wood")
            object:removeIntermediate(items.item3)
            assert.are.same(output, {
                [items.item1] = true,
                [items.item2] = true,
                [items.item4] = true,
                [items.item5] = true,
                [items.wood] = true,
            })
            local selectionFlow = object.gui.selectionFlow
            assert.is_nil(selectionFlow.children[2])
            local sprites = {
                ["item/item1"] = true,
                ["item/item2"] = true,
                ["item/item4"] = true,
                ["item/item5"] = true,
                ["item/wood"] = true,
            }
            for _,frame in ipairs(selectionFlow.children[1].children) do
                local spritePath = frame.children[1].sprite
                assert.is_true(sprites[spritePath], spritePath)
                sprites[spritePath] = nil
            end
            assert.is_nil(next(sprites))
        end)
    end)

    describe("-- GUI:", function()
        before_each(function()
            object:open(parent)
        end)

        it("AddIntermediateButton", function()
            local rawElement = object.gui.addFluidButton.rawElement
            rawElement.elem_value = "steam"
            GuiElement.on_gui_elem_changed{
                player_index = appTestbench.player.index,
                element = rawElement,
            }
            assert.are.same(output, {
                [items.item1] = true,
                [items.item2] = true,
                [items.item3] = true,
                [items.item4] = true,
                [items.item5] = true,
                [fluids.steam] = true,
            })
            assert.is_nil(rawElement.elem_value)
        end)

        it("RemoveIntermediateButton", function()
            local rawElement = object.gui.removeButtons[items.item4].rawElement
            GuiElement.on_gui_click{
                player_index = appTestbench.player.index,
                element = rawElement,
            }
            assert.are.same(output, {
                [items.item1] = true,
                [items.item2] = true,
                [items.item3] = true,
                [items.item5] = true,
            })
        end)
    end)
end)
