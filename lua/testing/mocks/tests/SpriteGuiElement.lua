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

local MockObject = require("lua/testing/mocks/MockObject")
local SpriteGuiElement = require("lua/testing/mocks/SpriteGuiElement")

describe("SpriteGuiElement", function()
    local cArgs
    local object
    before_each(function()
        object = SpriteGuiElement.make({
            type = "sprite",
            sprite = "foobar",
        }, {player_index = 1234})
    end)

    it(".make()", function()
        local data = MockObject.getData(object)
        assert.are.equals(data.type, "sprite")
        assert.are.equals(data.sprite, "foobar")
    end)

    describe(":sprite", function()
        it("-- read", function()
            assert.are.equals(object.sprite, "foobar")
        end)

        it("-- valid write", function()
            object.sprite = "barfoo"
            assert.are.equals(MockObject.getData(object).sprite, "barfoo")
        end)

        it("-- invalid write", function()
            assert.error(function()
                object.sprite = {}
            end)
        end)
    end)
end)
