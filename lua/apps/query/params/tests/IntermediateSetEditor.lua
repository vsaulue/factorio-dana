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

local Force = require("lua/model/Force")
local GuiElement = require("lua/gui/GuiElement")
local IntermediateSetEditor = require("lua/apps/query/params/IntermediateSetEditor")
local MockFactorio = require("lua/testing/mocks/MockFactorio")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("IntermediateSetEditor (& GUI)", function()
    local factorio
    local player
    local parent
    local prototypes
    local force
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
        factorio = MockFactorio.make{
            rawData = rawData,
        }
        player = factorio:createPlayer{
            forceName = "player",
        }
        parent = player.gui.center
        factorio:setup()

        prototypes = PrototypeDatabase.new(factorio.game)
        force = Force.new{
            prototypes = prototypes,
            rawForce = factorio.game.forces.player,
        }
    end)

    local getFluid = function(fluidName)
        return prototypes.intermediates.fluid[fluidName]
    end

    local getItem = function(itemName)
        return prototypes.intermediates.item[itemName]
    end

    local object
    local output
    before_each(function()
        parent.clear()
        GuiElement.on_init()

        output = {}
        for i=1,5 do
            output[prototypes.intermediates.item["item"..i]] = true
        end

        object = IntermediateSetEditor.new{
            force = force,
            output = output,
        }
    end)

    it(".new()", function()
        assert.are.same(object, {
            output = output,
            force = force,
        })
    end)

    describe(".setmetatable()", function()
         local runTest = function()
            SaveLoadTester.run{
                objects = {
                    force = force,
                    object = object,
                    prototypes = prototypes,
                },
                metatableSetter = function(objects)
                    PrototypeDatabase.setmetatable(objects.prototypes)
                    Force.setmetatable(objects.force)
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
            assert.is_true(output[prototypes.intermediates.item.coal])
        end)

        it("-- with GUI", function()
            object:open(parent)
            object:addIntermediate("fluid", "water")
            local water = prototypes.intermediates.fluid.water
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
            assert.are.equals(object.gui.intermediateSetEditor, object)
            assert.are.equals(object.gui.selectionFlow, parent.children[1].children[2])
        end)

        it(":close()", function()
            object:close()
            assert.is_nil(rawget(object, "gui"))
            assert.are.equals(GuiElement.count(player.index), 0)
            assert.is_nil(parent.children[1])
        end)
    end)

    describe(":removeIntermediate()", function()
        it("-- no GUI", function()
            object:removeIntermediate(getItem("item1"))
            assert.are.same(output, {
                [getItem("item2")] = true,
                [getItem("item3")] = true,
                [getItem("item4")] = true,
                [getItem("item5")] = true,
            })
        end)

        it("-- with GUI", function()
            object:open(parent)
            object:addIntermediate("item", "wood")
            object:removeIntermediate(getItem("item3"))
            assert.are.same(output, {
                [getItem("item1")] = true,
                [getItem("item2")] = true,
                [getItem("item4")] = true,
                [getItem("item5")] = true,
                [getItem("wood")] = true,
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
                player_index = player.index,
                element = rawElement,
            }
            assert.are.same(output, {
                [getItem("item1")] = true,
                [getItem("item2")] = true,
                [getItem("item3")] = true,
                [getItem("item4")] = true,
                [getItem("item5")] = true,
                [getFluid("steam")] = true,
            })
            assert.is_nil(rawElement.elem_value)
        end)

        it("RemoveIntermediateButton", function()
            local rawElement = object.gui.removeButtons[getItem("item4")].rawElement
            GuiElement.on_gui_click{
                player_index = player.index,
                element = rawElement,
            }
            assert.are.same(output, {
                [getItem("item1")] = true,
                [getItem("item2")] = true,
                [getItem("item3")] = true,
                [getItem("item5")] = true,
            })
        end)
    end)
end)
