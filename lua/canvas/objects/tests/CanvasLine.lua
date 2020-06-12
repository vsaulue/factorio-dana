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
local CanvasLine = require("lua/canvas/objects/CanvasLine")

describe("CanvasLine", function()
    local object

    before_each(function()
        object = CanvasLine.makeFromInitData{
            from = {
                x = -1,
                y = -2,
            },
            to = {
                x = 3,
                y = 4,
            },
        }
    end)

    after_each(function()
        object = nil
    end)

    it("setmetatable()", function()
        local dummyCanvasLine = {}
        CanvasLine.setmetatable(dummyCanvasLine)
        assert.is_not_nil(dummyCanvasLine.isCollidingWithAabb)
    end)

    it(":close()", function()
        local id = object.id
        object:close()
        assert.are.equals(id.type, "destroyed")
    end)

    describe(":isCollidingWithAabb()", function()
        it("-- strictly over", function()
            local aabb = Aabb.new{
                xMin = -10,
                xMax = 10,
                yMin = -2.5,
                yMax = -2.1,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- strictly under", function()
            local aabb = Aabb.new{
                xMin = -10,
                xMax = 10,
                yMin = 4.1,
                yMax = 5,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- strictly left", function()
            local aabb = Aabb.new{
                xMin = -3,
                xMax = -1.01,
                yMin = -10,
                yMax = 10,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- strictly right", function()
            local aabb = Aabb.new{
                xMin = 3.01,
                xMax = 5,
                yMin = -10,
                yMax = 10,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- under (not strict)", function()
            local aabb = Aabb.new{
                xMin = -100,
                xMax = 0,
                yMin = 0,
                yMax = 100,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- over (not strict)", function()
            local aabb = Aabb.new{
                xMin = 1,
                xMax = 100,
                yMin = -100,
                yMax = 0,
            }
            assert.is_false(object:isCollidingWithAabb(aabb))
        end)

        it("-- intersect (corner)", function()
            local aabb = Aabb.new{
                xMin = 0,
                xMax = 1,
                yMin = -2,
                yMax = 0,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- intersect (side)", function()
            local aabb = Aabb.new{
                xMin = 0,
                xMax = 0.5,
                yMin = -1,
                yMax = 1,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- 1 end inside", function()
            local aabb = Aabb.new{
                xMin = -1.01,
                xMax = -0.99,
                yMin = -2.01,
                yMax = -1.99,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)

        it("-- 2 ends inside", function()
            local aabb = Aabb.new{
                xMin = -1.01,
                xMax = 3.01,
                yMin = -2.01,
                yMax = 4.01,
            }
            assert.is_true(object:isCollidingWithAabb(aabb))
        end)
    end)
end)
