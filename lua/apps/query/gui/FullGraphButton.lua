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
local GraphApp = require("lua/apps/graph/GraphApp")
local GuiElement = require("lua/gui/GuiElement")

local cLogger = ClassLogger.new{className = "queryApp/FullGraphButton"}

local Metatable

-- Button to display the full recipe graph.
--
-- RO Fields:
-- * appController: AppController of the application owning this object.
--
local FullGraphButton = ErrorOnInvalidRead.new{
	-- Creates a new FullGraphButton object.
	--
	-- Args:
	-- * object: table to turn into a FullGraphButton object (required field: appController).
	--
	-- Returns: The argument turned into a FullGraphButton object.
	--
	new = function(object)
		local controller = cLogger:assertField(object, "appController")
		setmetatable(object, Metatable)

		local rawPlayer = controller.appResources.rawPlayer
		object.rawElement = rawPlayer.gui.center.add{
			type = "button",
			caption = "Full graph",
		}
		GuiElement.bind(object)

		return object
	end,

	-- Restores the metatable of an FullGraphButton object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
	setmetatable = function(object)
		setmetatable(object, Metatable)
	end,
}

-- Metatable of the FullGraphButton class.
Metatable = {
	__index = ErrorOnInvalidRead.new{
		-- Releases all API resources of this object.
        --
        -- Args:
        -- * self: FullGraphButton object.
        --
		close = function(self)
			GuiElement.destroy(self.rawElement)
		end,

		-- Implements GuiElement:onClick().
		onClick = function(self, event)
			local graph,sourceVertices = GraphApp.makeDefaultGraphAndSource(self.appController.appResources.force)
			self.appController:makeAndSwitchApp{
				appName = "graph",
				graph = graph,
				sourceVertices = sourceVertices,
			}
		end,
	}
}

return FullGraphButton
