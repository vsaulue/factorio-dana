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

local AbstractFactory = require("lua/class/AbstractFactory")

describe("AbstractFactory", function()
    local makeClass = function(info)
        local metatable = {
            __index = info.__index,
        }
        return {
            new = function(object)
                if info.preNew then
                    info.preNew(object)
                end
                setmetatable(object, metatable)
                return object
            end,

            setmetatable = function(object)
                setmetatable(object, metatable)
            end,
        }
    end

    local aClass1 = {
        new = function(object)
            object.classIndex = "1"
        end,
    }
    local class1a = makeClass{
        __index = {metaName = "class1a"},
        preNew = function(object)
            aClass1.new(object)
            object.subclassIndex = "a"
        end,
    }
    local class1b = makeClass{
        __index = {metaName = "class1b"},
        preNew = function(object)
            aClass1.new(object)
            object.subclassIndex = "b"
        end,
    }
    local class2 = makeClass{
        __index = {metaName = "class2"},
        preNew = function(object)
            object.classIndex = "2"
        end,
    }

    local factory
    before_each(function()
        aClass1.Factory = AbstractFactory.new{
            enableMake = true,

            getClassNameOfObject = function(object)
                return object.subclassIndex
            end,
        }
        aClass1.Factory:registerClass("a", class1a)
        aClass1.Factory:registerClass("b", class1b)

        factory = AbstractFactory.new{
            enableMake = true,

            getClassNameOfObject = function(object)
                return object.classIndex
            end,
        }
        factory:registerClass("1", aClass1)
        factory:registerClass("2", class2)
    end)

    it(".make()", function()
        assert.are.same(aClass1.Factory, {
            classes = {
                a = class1a,
                b = class1b,
            },
            enableMake = true,
            getClassNameOfObject = aClass1.Factory.getClassNameOfObject,
        })
    end)

    describe(":registerClass()", function()
        it("-- invalid (wrong class table)", function()
            local class3 = {
                new = function(object)
                    object.classIndex = "3"
                    return object
                end,
            }
            assert.error(function()
                factory:registerClass("3", class3)
            end)
        end)
    end)

    describe(":make()", function()
        it("-- valid, direct", function()
            local object = {
                classIndex = "2"
            }
            local result = factory:make(object)
            assert.are.equals(object, result)
            assert.are.equals(object.metaName, "class2")
        end)

        it("-- valid, chained", function()
            local object = {
                classIndex = "1",
                subclassIndex = "b",
            }
            local result = factory:make(object)
            assert.are.equals(object, result)
            assert.are.equals(object.metaName, "class1b")
        end)
    end)

    describe(":makeClassTable()", function()
        local classTable
        setup(function()
            classTable = factory:makeClassTable()
        end)

        it(".new()", function()
            local object = {
                classIndex = "2",
            }
            local result = classTable.new(object)
            assert.are.equals(object, result)
            assert.are.equals(object.metaName, "class2")
        end)

        it(".setmetatable()", function()
            local object = {
                classIndex = "1",
                subclassIndex = "b",
            }
            classTable.setmetatable(object)
            assert.are.equals(object.metaName, "class1b")
        end)
    end)

    it(":restoreMetatable()", function()
        local object = {
            classIndex = "1",
            subclassIndex = "a",
        }
        factory:restoreMetatable(object)
        assert.are.equals(object.metaName, "class1a")
    end)
end)
