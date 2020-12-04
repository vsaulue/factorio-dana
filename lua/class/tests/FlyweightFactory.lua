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

local FlyweightFactory = require("lua/class/FlyweightFactory")

describe("FlyweightFactory", function()
    local equals = function(o1, o2)
        return o1.name == o2.name and o1.type == o2.type
    end
    local make = function(data)
        return {
            type = data.type,
            name = data.name,
        }
    end

    local factory
    before_each(function()
        factory = FlyweightFactory.new{
            make = make,
            valueEquals = equals,
            [1] = {type = "item", name = "wood"},
            [2] = {type = "fluid", name = "water"},
        }
        factory.count = 2
    end)

    describe(":get()", function()
        it("-- cache hit", function()
            assert.are.equals(factory:get{type = "fluid", name = "water"}, factory[2])
        end)

        it("-- cache miss", function()
            local input = {type = "item", name = "coal"}
            local result = factory:get(input)
            assert.are.same(result, input)
            assert.are_not.equals(result, input)
            assert.are.equals(result, factory[3])
            assert.are.equals(factory.count, 3)
        end)
    end)
end)
