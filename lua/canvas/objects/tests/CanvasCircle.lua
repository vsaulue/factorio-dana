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

_G.rendering = require("lua/canvas/objects/tests/MockRendering")

local Aabb = require("lua/canvas/Aabb")
local CanvasCircle = require("lua/canvas/objects/CanvasCircle")

describe("CanvasLine", function()
    local object

    before_each(function()
        object = CanvasCircle.makeFromInitData{
            target = {
                x = 7,
                y = -2,
            },
            radius = 3,
        }
    end)

    after_each(function()
        object = nil
    end)

    it("setmetatable()", function()
        local dummyCanvasCircle = {}
        CanvasCircle.setmetatable(dummyCanvasCircle)
        assert.is_not_nil(dummyCanvasCircle.isCollidingWithAabb)
    end)

    it(":close()", function()
        local id = object.id
        object:close()
        assert.are.equals(id.type, "destroyed")
    end)

    describe(":isCollidingWithAabb()", function()
        it("-- center inside AABB.", function()
            local aabb = Aabb.new{
                xMin = 6.9,
                xMax = 7.01,
                yMin = -2.1,
                yMax = -1.98,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- X=const edge collision.", function()
            local aabb = Aabb.new{
                xMin = 3,
                xMax = 4.02,
                yMin = -3,
                yMax = 0,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- Y=const edge collision.", function()
            local aabb = Aabb.new{
                xMin = 6.99,
                xMax = 7.01,
                yMin = 0.99,
                yMax = 100,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- corner collision.", function()
            local aabb = Aabb.new{
                xMin = 7 + 3 / math.sqrt(2),
                xMax = 10,
                yMin = -10,
                yMax = -2 - 3 / math.sqrt(2) + 0.0001,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- X-const separation.", function()
            local aabb = Aabb.new{
                xMin = 3,
                xMax = 3.99,
                yMin = -3,
                yMax = 0,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- Y-const separation.", function()
            local aabb = Aabb.new{
                xMin = 6.99,
                xMax = 7.01,
                yMin = 1.01,
                yMax = 100,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- corner separation.", function()
            local aabb = Aabb.new{
                xMin = 7 + 3 / math.sqrt(2),
                xMax = 10,
                yMin = -2 + 3 / math.sqrt(2) + 0.0001,
                yMax = 2,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)
    end)
end)