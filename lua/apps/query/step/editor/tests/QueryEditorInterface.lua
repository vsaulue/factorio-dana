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

local QueryEditorInterface = require("lua/apps/query/step/editor/QueryEditorInterface")

describe("QueryEditorInterface", function()
    local makeValid = function()
        return {
            getGuiUpcalls = function() end,
            setParamsEditor = function() end,
        }
    end

    describe(".checkMethods()", function()
        local testMissingField = function(fieldName)
            local object = makeValid()
            object[fieldName] = nil
            assert.error(function()
                QueryEditorInterface.checkMethods(object)
            end)
        end

        it("-- valid", function()
            QueryEditorInterface.checkMethods(makeValid())
        end)

        describe("-- missing", function()
            it("setParamsEditor()", function()
                testMissingField("setParamsEditor")
            end)

            it("getGuiUpcalls()", function()
                testMissingField("getGuiUpcalls")
            end)
        end)
    end)
end)
