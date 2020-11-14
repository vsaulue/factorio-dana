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

local ClassLogger = require("lua/logger/ClassLogger")
local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

local cLogger = ClassLogger.new{className = "GuiAbstractQueryEditor"}

local Metatable

-- Instanciated GUI of an IntermediateSetEditor.
--
-- RO Fields:
-- * controller: AbstractQueryEditor. Owner of this GUI.
-- * parent: LuaGuiElement. Element containing this GUI.
--
local GuiAbstractQueryEditor = ErrorOnInvalidRead.new{
    -- Creates a new GuiAbstractQueryEditor object.
    --
    -- Args:
    -- * object: table. Required fields: controller, parent.
    --
    -- Returns: GuiAbstractQueryEditor. `object` turned into the desired type.
    --
    new = function(object)
        local controller = cLogger:assertField(object, "controller")
        local parent = cLogger:assertField(object, "parent")

        local paramsEditor = rawget(controller, "paramsEditor")
        if paramsEditor then
            paramsEditor:open(parent)
        end

        setmetatable(object, Metatable)
        return object
    end,

    -- Restores the metatable of an GuiAbstractQueryEditor object, and all its owned objects.
    --
    -- Args:
    -- * object: table to modify.
    --
    setmetatable = function(object)
        setmetatable(object, Metatable)
    end,
}

-- Metatable of the GuiAbstractQueryEditor class.
Metatable = {
    __index = ErrorOnInvalidRead.new{
        -- Implements Closeable:close().
        close = function(self)
            -- no-op
        end,
    },
}

return GuiAbstractQueryEditor
