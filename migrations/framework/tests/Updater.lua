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

local Updater = require("migrations/framework/Updater")

-- Best logger mock ever.
_G.log = function(str) end

describe("Updater", function()
    describe(".assertModVersion()", function()
        local sampleModList

        before_each(function()
            sampleModList = {
                modA = "1.7.11",
                modB = "0.4.8",
            }
        end)

        it("-- valid (mod not installed)", function()
            Updater.assertModVersion(sampleModList, "modC", "0.0.0")
        end)

        it("-- valid (mod installed)", function()
            Updater.assertModVersion(sampleModList, "modB", "0.4.8")
        end)

        it("-- invalid", function()
            assert.error(function()
                Updater.assertModVersion(sampleModList, "modA", "1.10.0")
            end)
        end)
    end)

    describe(".run(min,target)", function()
        local flag

        local flagSetter = function()
            flag = true
        end

        before_each(function()
            flag =  false
            _G.global = {
                Dana = {
                    version = "7.5.1",
                },
            }
        end)

        it("-- valid (min < Dana < target)", function()
            Updater.run("7.5.0", "7.5.2", flagSetter)
            assert.is_true(flag)
            assert.are.equals(global.Dana.version, "7.5.2")
        end)

        it("-- valid (min == Dana < target)", function()
            Updater.run("7.5.1", "7.5.11", flagSetter)
            assert.is_true(flag)
            assert.are.equals(global.Dana.version, "7.5.11")
        end)

        it("-- valid (min == Dana < target) + script updated version", function()
            Updater.run("7.5.1", "7.5.11", function()
                flag = true
                global.Dana.version = "7.5.12"
            end)
            assert.is_true(flag)
            assert.are.equals(global.Dana.version, "7.5.12")
        end)

        it("-- skip (min < Dana == target)", function()
            Updater.run("7.4.0", "7.5.1", flagSetter)
            assert.is_false(flag)
            assert.are.equals(global.Dana.version, "7.5.1")
        end)

        it("-- skip (min < target < Dana)", function()
            Updater.run("7.4.11", "7.5.0", flagSetter)
            assert.is_false(flag)
            assert.are.equals(global.Dana.version, "7.5.1")
        end)

        it("-- error (Dana < min)", function()
            assert.error(function()
                Updater.run("7.5.2", "11.12.13", flagSetter)
            end)
            assert.is_false(flag)
            assert.are.equals(global.Dana.version, "7.5.1")
        end)

        it("-- skip (min < Dana < target) + variable length", function()
            Updater.run("7.4", "7.5", flagSetter)
            assert.is_false(flag)
            assert.are.equals(global.Dana.version, "7.5.1")
        end)

        it("-- valid (min < Dana < target) + variable length", function()
            Updater.run("7.5", "7.5.1.1", flagSetter)
            assert.is_true(flag)
            assert.are.equals(global.Dana.version, "7.5.1.1")
        end)
    end)
end)
