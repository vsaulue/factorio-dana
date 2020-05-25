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

local Tree = require("lua/containers/Tree")

describe("Tree", function()
    local tree

    before_each(function()
        tree = Tree.new()
    end)

    after_each(function()
        tree = nil
    end)

    it("constructor", function()
        assert.is_not_nil(tree.children)
        assert.is_nil(rawget(tree, "parent"))
    end)

    describe(":addChild()", function()
        it("new node", function()
            local child = Tree.new()
            tree:addChild(child)
            assert.is_true(tree.children[child])
            assert.is_nil(rawget(tree, "parent"))
            assert.are.equals(child.parent, tree)
        end)

        it("error if the node is inserted twice", function()
            local tree2 = Tree.new()
            local child = Tree.new()
            tree2:addChild(child)
            assert.error(function()
                tree:addChild(child)
            end)
        end)
    end)
end)
