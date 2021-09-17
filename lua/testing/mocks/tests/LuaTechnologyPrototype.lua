-- This file is part of Dana.
-- Copyright (C) 2020,2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local LuaTechnologyPrototype = require("lua/testing/mocks/LuaTechnologyPrototype")
local MockObject = require("lua/testing/mocks/MockObject")

describe("LuaTechnologyPrototype", function()
    describe(".make()", function()
        it("-- valid, no prerequisites", function()
            local object = LuaTechnologyPrototype.make{
                type = "technology",
                name = "vaporware",
            }
            assert.are.equals(getmetatable(object).className, "LuaTechnologyPrototype")
            local mockData = MockObject.getData(object)
            assert.are.same(mockData.prerequisites, {})
        end)

        it("-- valid, prerequisites", function()
            local object = LuaTechnologyPrototype.make{
                type = "technology",
                name = "vaporware-2",
                prerequisites = {"vaporware-1"},
            }
            assert.are.equals(getmetatable(object).className, "LuaTechnologyPrototype")

            local mockData = MockObject.getData(object)
            assert.are.same(mockData.prerequisites, {
                ["vaporware-1"] = true,
            })
        end)

        it("-- wrong type", function()
            assert.error(function()
                LuaTechnologyPrototype.make{
                    type = "item",
                    name = "vaporware",
                }
            end)
        end)

        it("-- invalid prerequisites (table expected)", function()
            assert.error(function()
                LuaTechnologyPrototype.make{
                    type = "technology",
                    name = "vaporware",
                    prerequisites = "foobar",
                }
            end)
        end)

        it("-- invalid prerequisites (string value expected)", function()
            assert.error(function()
                LuaTechnologyPrototype.make{
                    type = "technology",
                    name = "vaporware",
                    prerequisites = { {"basic-vaporware"} },
                }
            end)
        end)
    end)

    describe("", function()
        local object
        before_each(function()
            object = LuaTechnologyPrototype.make{
                type = "technology",
                name = "vaporware",
            }
        end)

        it(":localised_name", function()
            assert.are.same(object.localised_name, {"technology-name.vaporware"})
        end)

        it(":type", function()
            local pType
            assert.error(function()
                pType = object.type
            end)
        end)

        it("-- parent properties", function()
            assert.are.equals(object.name, "vaporware")
        end)
    end)
end)
