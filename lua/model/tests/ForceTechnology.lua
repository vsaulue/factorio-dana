-- This file is part of Dana.
-- Copyright (C) 2021 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ForceTechnology = require("lua/model/ForceTechnology")
local LuaGameScript = require("lua/testing/mocks/LuaGameScript")
local PrototypeDatabase = require("lua/model/PrototypeDatabase")
local SaveLoadTester = require("lua/testing/SaveLoadTester")

describe("ForceTechnology", function()
    local gameScript
    local prototypes
    setup(function()
        gameScript = LuaGameScript.make{
            technology = {
                automation = {
                    type = "technology",
                    name = "automation",
                },
            },
        }
        gameScript.create_force("beWithYou")
        prototypes = PrototypeDatabase.new(gameScript)
    end)

    local object
    before_each(function()
        object = ForceTechnology.make(gameScript.technology_prototypes.automation, prototypes.transforms)
    end)

    it(".new()", function()
        assert.are.same(object, {
            rawTechnology = gameScript.technology_prototypes.automation,
            researchTransform = prototypes.transforms.research.automation,
        })
    end)

    it(".setmetatable()", function()
        SaveLoadTester.run{
            objects = {
                prototypes = prototypes,
                object = object,
            },
            metatableSetter = function(objects)
                PrototypeDatabase.setmetatable(objects.prototypes)
                ForceTechnology.setmetatable(objects.object)
            end,
        }
    end)
end)
