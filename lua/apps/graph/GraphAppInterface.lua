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

local cLogger = ClassLogger.new{className = "GraphInterface"}

local checkMethods

-- Interface containing callbacks from top-level controller for applications.
--
local GraphInterface = ErrorOnInvalidRead.new{
    -- Checks all methods & fields.
    --
    -- Args:
    -- * object: GraphInterface.
    --
    check = function(object)
        cLogger:assertField(object, "appResources")
        checkMethods(object)
    end,

    -- Checks that all methods are implemented.
    --
    -- Args:
    -- * object: GraphInterface.
    --
    checkMethods = function(object)
        cLogger:assertField(object, "newQuery")
        cLogger:assertField(object, "viewGraphCenter")
        cLogger:assertField(object, "viewLegend")
    end,
}

--[[
Metatable = {
    __index = {
        -- Switches to the QueryApp.
        --
        -- Args:
        -- * self: GraphApp.
        --
        newQuery = function(self)
            self.appResources:makeAndSwitchApp{
                appName = "query",
            }
        end,

        -- Moves the view to the center of the graph.
        --
        -- Args:
        -- * self: GraphApp object.
        --
        viewGraphCenter = function(self)
            local lc = self.renderer.layoutCoordinates
            if lc.xMin ~= math.huge then
                self.appResources:setPosition{
                    x = (lc.xMin + lc.xMax) / 2,
                    y = (lc.yMin + lc.yMax) / 2,
                }
            end
        end,

        -- Moves the view to the legend of the graph.
        --
        -- Args:
        -- * self: GraphApp object.
        --
        viewLegend = function(self)
            local legendPos = rawget(self.renderer, "legendCenter")
            if legendPos then
                self.appResources:setPosition(self.renderer.legendCenter)
            end
        end,
    },
}
--]]

checkMethods = GraphInterface.checkMethods

return GraphInterface
