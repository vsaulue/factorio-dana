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

local SpritePath = require("lua/testing/mocks/SpritePath")

describe("SpritePath", function()
    it(".check() -- valid", function()
        local value = "item/coal"
        assert.are.equals(value, SpritePath.check(value))
    end)

    it(".check() -- invalid", function()
        local value = 12345
        assert.error(function()
            SpritePath.check(value)
        end)
    end)
end)
