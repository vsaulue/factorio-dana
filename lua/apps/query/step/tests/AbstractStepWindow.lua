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
local EmptyGraphWindow = require("lua/apps/query/step/EmptyGraphWindow")
local QueryAppInterface = require("lua/apps/query/QueryAppInterface")

describe("EmptyGraphWindow", function()
    local appInterface
    local appTestbench
    setup(function()
        appTestbench = AppTestbench.make{
            rawData = {
                fluid = {
                    steam = {type = "fluid", name = "steam"},
                    water = {type = "fluid", name = "water"},
                },
                item = {
                    coal = {type = "item", name = "coal"},
                    wood = {type = "item", name = "wood"},
                },
            },
        }
        appTestbench:setup()

        appInterface = AutoLoaded.new{
            appResources = appTestbench.appResources,
            pushStepWindow = function() end,
            popStepWindow = function() end,
            runQueryAndDraw = function() end,
        }
        QueryAppInterface.check(appInterface)
    end)

    local controller
    before_each(function()
        controller = EmptyGraphWindow.new{
            appInterface = appInterface,
        }
    end)

    it(":getGuiUpcalls()", function()
        assert.are.equals(appTestbench.appResources, controller:getGuiUpcalls())
    end)
end)
