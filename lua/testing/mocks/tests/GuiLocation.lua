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

local GuiLocation = require("lua/testing/mocks/GuiLocation")

describe("GuiLocation.parse()", function()
    local object
    before_each(function()
        object = {x = -1, y = -1}
    end)

    it("-- valid {x=,y=}", function()
        GuiLocation.parse(object, {x=-0.1, y=15.8})
        assert.are.same(object, {
            x = -1,
            y = 15
        })
    end)

    it("-- valid {a,b}", function()
        GuiLocation.parse(object, {7.1, 4.7})
        assert.are.same(object, {
            x = 7,
            y = 4,
        })
    end)

    it("-- invalid {x=}", function()
        assert.error(function()
            GuiLocation.parse(object, {x=123})
        end)
    end)

    it("-- invalid {a}", function()
        assert.error(function()
            GuiLocation.parse(object, {456})
        end)
    end)
end)
