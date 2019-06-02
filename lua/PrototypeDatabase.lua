-- This file is part of Dana.
-- Copyright (C) 2019 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local Logger = require("lua/Logger")

-- Object holding prototypes wrapper for this mod.
--
-- Two goals:
-- * Associate a unique Lua object for each LuaPrototype (making them usable as table keys).
-- * Attach any useful data for the mod.
--
-- Stored in global: yes.
--
-- RO properties:
-- * entries: 2-dim table of all the prototypes wrapper (1st index: type, 2nd index: name).
--
-- Methods:
-- * rebuild: drops the current content of the database, and rebuild it from scratch.
-- * getEntry: gets the wrapper of a prototype.
--
local PrototypeDatabase = {
    new = nil, -- implemented later
    setmetatable = nil, -- implemented later
}

-- Implementation stuff (private scope).
local Impl = {
    -- Metatable of the PrototypeDatabase class.
    Metatable = {
        __index = {
            rebuild = nil, -- implemented later

            getEntry = function(self,prototypeInfo)
                local typeTable = self.entries[prototypeInfo.type]
                local result = nil
                if typeTable then
                    result = typeTable[prototypeInfo.name]
                    if not result then
                        Logger.error("PrototypeDatabase: unknown entry {type= ".. prototypeInfo.type .. ",name= " .. prototypeInfo.name .. "}")
                    end
                else
                    Logger.error("PrototypeDatabase: unsupported type: " .. prototypeInfo.type)
                end
                return result
            end
        },
    },
}

-- Resets the content of the database.
--
-- Args:
-- * self: PrototypeDatabase object.
-- * gameScript: game object holding the new prototypes.
--
function Impl.Metatable.__index.rebuild(self,gameScript)
    self.entries = {
        boiler = {},
        fluid = {},
        item = {},
        ["offshore-pump"] = {},
        recipe = {},
        resource = {},
    }
    for _,item in pairs(gameScript.item_prototypes) do
        self.entries.item[item.name] = {
            rawPrototype = item,
        }
    end
    for _,fluid in pairs(gameScript.fluid_prototypes) do
        self.entries.fluid[fluid.name] = {
            rawPrototype = fluid,
        }
    end
    for _,entity in pairs(gameScript.entity_prototypes) do
        if entity.type == "resource" then
            local mineable_props = entity.mineable_properties
            if mineable_props.minable then
                local newResource = {
                    rawPrototype = entity,
                    ingredients = {},
                    products = {},
                }
                for index,product in pairs(mineable_props.products) do
                    newResource.products[index] = self:getEntry(product)
                end
                local fluidName = mineable_props.required_fluid
                if fluidName then
                    newResource.ingredients[1] = self.entries.fluid[fluidName]
                end
                self.entries.resource[entity.name] = newResource
            end
        elseif entity.type == "offshore-pump" then
            local newOffshorePump = {
                rawPrototype = entity,
                ingredients = {},
                products = {self.entries.fluid[entity.fluid.name]},
            }
            self.entries["offshore-pump"][entity.name] = newOffshorePump
        elseif entity.type == "boiler" then
            local inputs = {}
            local outputs = {}
            for _,fluidbox in pairs(entity.fluidbox_prototypes) do
                if fluidbox.filter then
                    local fluid = self.entries.fluid[fluidbox.filter.name]
                    local boxType = fluidbox.production_type
                    if boxType == "output" then
                        table.insert(outputs, fluid)
                    elseif boxType == "input-output" or boxType == "input" then
                        table.insert(inputs, fluid)
                    end
                end
            end
            if inputs[1] and outputs[1] then
                if #inputs == 1 and #outputs == 1 then
                    self.entries.boiler[entity.name] = {
                        rawPrototype = entity,
                        ingredients = inputs,
                        products = outputs,
                    }
                else
                    Logger.warn("Boiler prototype '" .. entity.name .. "' ignored (multiple inputs or outputs).")
                end
            end
        end
    end
    for _,recipe in pairs(gameScript.recipe_prototypes) do
        local newRecipe = {
            rawPrototype = recipe,
            ingredients = {},
            products = {},
        }
        for index,product in pairs(recipe.products) do
            newRecipe.products[index] = self:getEntry(product)
        end
        for index,ingredient in pairs(recipe.ingredients) do
            newRecipe.ingredients[index] = self:getEntry(ingredient)
        end
        self.entries.recipe[recipe.name] = newRecipe
    end
end

-- Creates a new PrototypeDatabase object.
--
-- Args:
-- * gameScript: LuaGameScript object containing the initial prototypes.
--
-- Returns: A PrototypeDatabase object, populated from the argument.
--
function PrototypeDatabase.new(gameScript)
    local result = {}
    setmetatable(result, Impl.Metatable)
    result:rebuild(gameScript)
    return result
end

-- Assigns the metatable of PrototypeDatabase class to the argument.
--
-- Intended to restore metatable of objects in the global table.
--
-- Args:
-- * object: Table to modify.
--
function PrototypeDatabase.setmetatable(object)
    setmetatable(object, Impl.Metatable)
end


return PrototypeDatabase
