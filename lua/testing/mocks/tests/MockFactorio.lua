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

local MockFactorio = require("lua/testing/mocks/MockFactorio")

describe("MockFactorio", function()
    local rawData = {
        item = {
            wood = {type = "item", name = "wood"},
        },
    }

    local object
    before_each(function()
        object = MockFactorio.make{
            rawData = rawData,
        }
    end)

    after_each(function()
        _G.game = nil
        _G.global = nil
    end)

    it(".make()", function()
        local wood = object.game.item_prototypes.wood
        assert.are.equals(wood.name, "wood")
    end)

    it(":createPlayer()", function()
        local player = object:createPlayer{
            forceName = "player",
        }
        assert.are.equals(object.game.players[player.index], player)
        assert.are.equals(object.game.forces.player, player.force)
    end)

    it(":setup()", function()
        object:setup()
        assert.are.equals(object.game, game)
        assert.are.equals(object.global, global)
    end)
end)
