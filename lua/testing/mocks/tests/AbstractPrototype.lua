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

local AbstractPrototype = require("lua/testing/mocks/AbstractPrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("AbstractPrototype", function()
    describe(".make()", function()
        it("-- valid", function()
            local object = AbstractPrototype.make({
                type = "item",
                name = "yeet!",
            })
            assert.are.equals(getmetatable(object).className, "AbstractPrototype")
        end)

        it("-- invalid name", function()
            assert.error(function()
                AbstractPrototype.make({
                    type = "item",
                    name = 7,
                })
            end)
        end)

        it("-- unknown type", function()
            assert.error(function()
                AbstractPrototype.make({
                    type = "yeet!",
                    name = "item",
                })
            end)
        end)
    end)

    describe(":", function()
        local object
        before_each(function()
            object = AbstractPrototype.make({
                type = "item",
                name = "yeet!",
            })
        end)

        it("localised_name -- read", function()
            assert.are.same(object.localised_name, {"item-name.yeet!"})
        end)

        it("localised_name -- write", function()
            assert.error(function()
                object.localised_name = {"kilroy"}
            end)
        end)

        it("name -- read", function()
            assert.are.equals(object.name, "yeet!")
        end)

        it("name -- write", function()
            assert.error(function()
                object.name = "wololo"
            end)
        end)

        it("type -- read", function()
            assert.are.equals(object.type, "item")
        end)

        it("type -- write", function()
            assert.error(function()
                object.type = "item"
            end)
        end)

        it("valid", function()
            assert.is_true(object.valid)
            MockObject.invalidate(object)
            assert.is_false(object.valid)
        end)
    end)
end)
