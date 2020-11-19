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

local EmptyGuiElement = require("lua/testing/mocks/EmptyGuiElement")
local MockObject = require("lua/testing/mocks/MockObject")

describe("EmptyGuiElement", function()
    it(".new()", function()
        local object = EmptyGuiElement.make({
            type = "empty-widget",
        }, {player_index = 1234})
        assert.are.equals(MockObject.getData(object).type, "empty-widget")
    end)
end)
