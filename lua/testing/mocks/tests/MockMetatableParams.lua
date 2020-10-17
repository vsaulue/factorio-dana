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

local MockMetatableParams = require("lua/testing/mocks/MockMetatableParams")

describe("MockMetatableParams", function()
    describe(".check()", function()
        it("-- valid", function()
            local object = MockMetatableParams.check{
                className = "foobar",
                getters = {
                    was = function() end,
                },
                setters = {
                    here = function() end,
                },
            }
        end)

        it("-- invalid (wrong key type)", function()
            assert.error(function()
                MockMetatableParams.check{
                    className = "foobar",
                    getters = {
                        [1] = true,
                    }
                }
            end)
        end)

        it("-- invalid (wrong value type)", function()
            assert.error(function()
                MockMetatableParams.check{
                    className = "foobar",
                    setters = {
                        barfoo = "wololo",
                    }
                }
            end)
        end)
    end)
end)
