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

local IndirectSinkBucketIndex = require("lua/model/IndirectSinkBucketIndex")

describe("IndirectSinkBucketIndex", function()
    local products
    local object
    before_each(function()
        products = {a = true, c = true}
        object = IndirectSinkBucketIndex.new{
            iAmount = 5,
            products = products,
            foo = "bar",
        }
    end)

    it(".copy()", function()
        assert.are.same(IndirectSinkBucketIndex.copy(object), {
            iAmount = 5,
            products = products,
        })
    end)

    it(".equals()", function()
        assert.is_true(IndirectSinkBucketIndex.equals(object, {
            iAmount = 5,
            products = products,
        }))
        assert.is_false(IndirectSinkBucketIndex.equals(object, {
            iAmount = 4,
            products = products,
        }))
        assert.is_false(IndirectSinkBucketIndex.equals(object, {
            iAmount = 5,
            products = {a = true, c = true},
        }))
    end)

    it(".new()", function()
        assert.are.same(object.iAmount, 5)
        assert.are.same(object.products, products)
    end)
end)
