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
local DirectedHypergraph = require("lua/hypergraph/DirectedHypergraph")
local DirectedHypergraphEdge = require("lua/hypergraph/DirectedHypergraphEdge")
local GuiElement = require("lua/gui/GuiElement")
local QueryApp = require("lua/apps/query/QueryApp")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("QueryApp", function()
    local appTestbench
    local recipes
    local vertexDists
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {
                item = {
                    ["iron-ore"] = {type = "item", name = "iron-ore"},
                    ["iron-plate"] = {type = "item", name = "iron-plate"},
                    ["steel-plate"] = {type = "item", name = "steel-plate"},
                },
                recipe = {
                    ["iron-plate"] = {
                        type = "recipe",
                        name = "iron-plate",
                        ingredients = {
                            {type = "item", name = "iron-ore", amount = 1},
                        },
                        results = {
                            {type = "item", name = "iron-plate", amount = 1},
                        },
                    },
                    ["steel-plate"] = {
                        type = "recipe",
                        name = "steel-plate",
                        ingredients = {
                            {type = "item", name = "iron-plate", amount = 5},
                        },
                        results = {
                            {type = "item", name = "steel-plate", amount = 1},
                        },
                    }
                },
                resource = {
                    ["iron-ore"] = {
                        type = "resource",
                        name = "iron-ore",
                        minable = {
                            results = {
                                {type = "item", name = "iron-ore", amount = 1},
                            },
                        }
                    },
                },
            },
        }
        appTestbench:setup()

        recipes = appTestbench.prototypes.transforms.recipe

        local items = appTestbench.prototypes.intermediates.item
        vertexDists = {
            [items["iron-ore"]] = 0,
            [items["iron-plate"]] = 1,
            [items["steel-plate"]] = 2,
        }
    end)

    local app
    before_each(function()
        GuiElement.on_init()
        appTestbench.player.gui.center.clear()
        appTestbench.player.gui.screen.clear()

        app = QueryApp.new{
            appResources = appTestbench.appResources,
        }
    end)

    local makeGraph = function(transforms)
        local result = DirectedHypergraph.new()
        for _,transform in pairs(transforms) do
            result:addEdge(DirectedHypergraphEdge.new{
                index = transform,
                inbound = transform.ingredients,
                outbound = transform.products,
            })
        end
        return result
    end

    it(".new()", function()
        assert.are.equals(app.appName, "query")
        assert.are.equals(app.stepWindows[1].stepName, "templateSelect")
        assert.is_nil(appTestbench.player.gui.center.children[1])
        assert.is_nil(appTestbench.player.gui.screen.children[1])
    end)

    describe(".setmetatable()", function()
        before_each(function()
            app:show()

            local selectButton = app.stepWindows[1].gui.templateButtons.HowToMake.rawElement
            GuiElement.on_gui_click{
                element = selectButton,
                player_index = selectButton.player_index,
            }

            local drawButton = app.stepWindows[2].gui.drawButton.rawElement
            GuiElement.on_gui_click{
                element = drawButton,
                player_index = drawButton.player_index,
            }
        end)

        local runTest = function()
            SaveLoadTester.run{
                objects = {
                    appTestbench = appTestbench,
                    app = app,
                },
                metatableSetter = function(objects)
                    AppTestbench.setmetatable(objects.appTestbench)
                    QueryApp.setmetatable(objects.app)
                end,
            }
        end

        it("-- with GUI", function()
            runTest()
        end)

        it("-- no GUI", function()
            app:hide()
            runTest()
        end)
    end)

    it(":close()", function()
        -- Setup
        app:show()

        local selectButton = app.stepWindows[1].gui.templateButtons.HowToMake.rawElement
        GuiElement.on_gui_click{
            element = selectButton,
            player_index = selectButton.player_index,
        }

        local drawButton = app.stepWindows[2].gui.drawButton.rawElement
        GuiElement.on_gui_click{
            element = drawButton,
            player_index = drawButton.player_index,
        }

        -- Test
        app:close()
        assert.are.equals(GuiElement.count(appTestbench.player.index), 0)
        assert.is_nil(appTestbench.player.gui.center.children[1])
        assert.is_nil(appTestbench.player.gui.screen.children[1])
    end)

    it(":repairGui()", function()
        -- Setup
        app:show()

        local selectButton = app.stepWindows[1].gui.templateButtons.HowToMake.rawElement
        GuiElement.on_gui_click{
            element = selectButton,
            player_index = selectButton.player_index,
        }

        -- Test
        local topGui = app.stepWindows[2].gui
        app:repairGui()
        assert.are.equals(app.stepWindows[2].gui, topGui)
        topGui.frame.destroy()
        app:repairGui()
        assert.are_not.equals(app.stepWindows[2].gui, topGui)
    end)

    describe("-- GUI:", function()
        before_each(function()
            app:show()
        end)

        it("TemplateSelectWindow.gui -> FullGraphButton", function()
            stub(appTestbench.upcalls, "makeAndSwitchApp")

            local fullGraphButton = app.stepWindows[1].gui.fullGraphButton.rawElement
            GuiElement.on_gui_click{
                element = fullGraphButton,
                player_index = fullGraphButton.player_index,
            }

            assert.stub(appTestbench.upcalls.makeAndSwitchApp).was.called_with(match.ref(appTestbench.upcalls), match.same{
                appName = "graph",
                graph = makeGraph{recipes["steel-plate"], recipes["iron-plate"]},
                vertexDists = vertexDists,
            })
        end)

        it("TemplateSelectWindow.gui -> HowToMake", function()
            local templateButton = app.stepWindows[1].gui.templateButtons.HowToMake.rawElement
            GuiElement.on_gui_click{
                element = templateButton,
                player_index = templateButton.player_index,
            }
            local editorWindow = app.stepWindows[2]
            assert.are.equals(editorWindow.query.queryType, "HowToMakeQuery")
            assert.is_not_nil(editorWindow.gui)
            assert.is_nil(rawget(app.stepWindows[1], "gui"))
        end)

        it("HowToMakeEditor.gui -> BackButton", function()
            -- Open HowToMakeEditor
            local templateButton = app.stepWindows[1].gui.templateButtons.HowToMake.rawElement
            GuiElement.on_gui_click{
                element = templateButton,
                player_index = templateButton.player_index,
            }

            -- Test
            local editorWindow = app.stepWindows[2]
            local backButton = editorWindow.gui.backButton.rawElement
            GuiElement.on_gui_click{
                element = backButton,
                player_index = backButton.player_index,
            }
            assert.is_nil(rawget(editorWindow, "gui"))
            assert.is_nil(rawget(app.stepWindows, 2))
            assert.is_not_nil(rawget(app.stepWindows[1], "gui"))
        end)

        it("HowToMakeEditor.gui -> DrawButton (empty graph)", function()
            -- Open HowToMakeEditor
            local templateButton = app.stepWindows[1].gui.templateButtons.HowToMake.rawElement
            GuiElement.on_gui_click{
                element = templateButton,
                player_index = templateButton.player_index,
            }

            -- Test
            local editorWindow = app.stepWindows[2]
            local drawButton = editorWindow.gui.drawButton.rawElement
            GuiElement.on_gui_click{
                element = drawButton,
                player_index = drawButton.player_index,
            }
            assert.are.equals(app.stepWindows[3].stepName, "emptyGraph")
            assert.is_nil(rawget(editorWindow, "gui"))
            assert.is_not_nil(app.stepWindows[3].gui)
        end)

        it("UsagesOfEditor.gui -> DrawButton (non-empty graph)", function()
            -- Open HowToMakeEditor
            local templateButton = app.stepWindows[1].gui.templateButtons.UsagesOf.rawElement
            GuiElement.on_gui_click{
                element = templateButton,
                player_index = templateButton.player_index,
            }

            -- Fill the query
            local editorWindow = app.stepWindows[2]

            local addItemButton = editorWindow.paramsEditor.setEditor.gui.addItemButton.rawElement
            addItemButton.elem_value = "iron-ore"
            GuiElement.on_gui_elem_changed{
                element = addItemButton,
                player_index = addItemButton.player_index,
            }

            local depthCheckbox = editorWindow.paramsEditor.gui.depthCheckbox.rawElement
            depthCheckbox.state = true
            GuiElement.on_gui_checked_state_changed{
                element = depthCheckbox,
                player_index = depthCheckbox.player_index,
            }

            local depthField = editorWindow.paramsEditor.gui.depthField.rawElement
            depthField.text = "1"
            GuiElement.on_gui_text_changed{
                element = depthField,
                player_index = depthField.player_index,
            }

            -- Test
            local upcalls = appTestbench.upcalls
            stub(upcalls, "makeAndSwitchApp")
            local drawButton = editorWindow.gui.drawButton.rawElement
            GuiElement.on_gui_click{
                element = drawButton,
                player_index = drawButton.player_index,
            }
            assert.stub(upcalls.makeAndSwitchApp).was.called_with(match.ref(upcalls), match.same{
                appName = "graph",
                graph = makeGraph{recipes["iron-plate"]},
                vertexDists = vertexDists,
            })
        end)
    end)
end)
