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

local MetaUtils = require("lua/class/MetaUtils")

describe("MetaUtils", function()
    local MyMetatable = {
        __index = {
            flag = "Spartaaa",
        },
    }
    local mySetter = function(object)
        setmetatable(object, MyMetatable)
    end

    describe(".safeSetField()", function()
        it("-- nil", function()
            local object = {}
            MetaUtils.safeSetField(object, "foo", mySetter)
            assert.is_nil(object.foo)
        end)

        it("-- not nil", function()
            local object = {
                foo = {},
            }
            MetaUtils.safeSetField(object, "foo", mySetter)
            assert.are.equals(object.foo.flag, "Spartaaa")
        end)
    end)
end)
