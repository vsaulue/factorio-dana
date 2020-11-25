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
local AutoLoaded = require("lua/testing/AutoLoaded")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local GuiElement = require("lua/gui/GuiElement")
local RendererSelection = require("lua/renderers/RendererSelection")
local SaveLoadTester = require("lua/testing/SaveLoadTester")
local TreeLinkNode = require("lua/layouts/TreeLinkNode")
local LinkSelectionPanel = require("lua/apps/graph/gui/LinkSelectionPanel")

describe("LinkSelectionPanel + GUI", function()
    local appTestbench
    local fakeSelectionWindow
    local selection
    local parent
    local root1,leaves1
    local root2,leaves2
    setup(function()
        local rawData = {
            item = {
                iron = {type = "item", name = "iron"},
                steel = {type = "item", name = "steel"},
            },
            recipe = {},
        }
        for i=1,9 do
            local recipeName = "recipe"..i
            rawData.recipe[recipeName] = {
                type = "recipe",
                name = recipeName,
                ingredients = {
                    {type = "item", name = "iron", amount = 5},
                },
                results = {
                    {type = "item", name = "steel", amount = 1},
                },
            }
        end

        appTestbench = AppTestbench.make{
            rawData = rawData,
        }
        appTestbench:setup()

        fakeSelectionWindow = AutoLoaded.new{
            selectPanel = function() end,
        }

        local items = appTestbench.prototypes.intermediates.item
        local recipes = appTestbench.prototypes.transforms.recipe
        local makeTree = function(rootIndex, isFromRoot)
            local root = TreeLinkNode.new{
                linkIndex = {
                    symbol = rootIndex,
                    isFromRoot = isFromRoot,
                }
            }
            local leaves = {}
            for i=1,9 do
                leaves[i] = TreeLinkNode.new{
                    edgeIndex = {index = recipes["recipe"..i]}
                }
                root:addChild(leaves[i])
            end
            return root,leaves
        end
        selection = RendererSelection.new()
        root1,leaves1 = makeTree(items.iron, true)
        root2,leaves2 = makeTree(items.steel, false)
        selection.links = ErrorOnInvalidRead.new{
            [leaves1[1]] = true,
            [leaves1[2]] = true,
            [leaves1[3]] = true,
            [leaves1[4]] = true,
            [leaves1[5]] = true,
            [leaves1[6]] = true,
            [leaves2[9]] = true,
        }

        parent = appTestbench.player.gui.screen
    end)

    local controller
    before_each(function()
        GuiElement.on_init()
        parent.clear()

        controller = LinkSelectionPanel.new{
            rawPlayer = appTestbench.player,
            selectionWindow = fakeSelectionWindow,
        }
    end)

    describe(".setmetatable()", function()
        local runTest = function()
            SaveLoadTester.run{
                objects = {
                    appTestbench = appTestbench,
                    controller = controller,
                },
                metatableSetter = function(objects)
                    AppTestbench.setmetatable(objects.appTestbench)
                    LinkSelectionPanel.setmetatable(objects.controller)
                end,
            }
        end

        it("-- no GUI", function()
            runTest()
        end)

        it("-- with GUI", function()
            controller:updateElements(selection)
            controller:open(parent)
            runTest()
        end)
    end)

    it(":updateElements()", function()
        controller:open(parent)
        controller:updateElements(selection)

        local ironDisplayed = false
        local steelDisplayed = false
        local checker = {
            ["item/iron"] = function(elemFlow)
                ironDisplayed = true
                assert.are.equals(elemFlow.children[2].caption, "⟶")
                assert.are.equals(elemFlow.children[3].type, "label")
            end,
            ["item/steel"] = function(elemFlow)
                steelDisplayed = true
                assert.are.equals(elemFlow.children[2].caption, "⟵")
                assert.are.equals(elemFlow.children[3].sprite, "recipe/recipe9")
            end,
        }
        local checkElemFlow = function(index)
            local elemFlow = controller.gui.mainFlow.content.children[index]
            checker[elemFlow.children[1].sprite](elemFlow)
        end
        checkElemFlow(1)
        checkElemFlow(2)
        assert.is_nil(controller.gui.mainFlow.content.children[3])
        assert.is_true(ironDisplayed and steelDisplayed)
    end)
end)
