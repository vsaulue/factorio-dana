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

local compareArrays
local getInstalledVersion
local parseVersion

-- Utility library for migration scripts.
--
local Updater = {
    -- Checks that the version of a specific mod (if it is installed).
    --
    -- This function generates an error if the mod is installed AND the version requirement is not met.
    -- If the mod is not installed, no error is generated.
    --
    -- Args:
    -- * mod[modName] -> string. Map giving the version of a set of mods, indexed by the mod's name.
    -- * modName: Name of the mod to check.
    -- * minimalVersion: String representing the minimal desired version for the mod.
    --
    assertModVersion = function(mods, modName, minimalVersion)
        local runningVersion = mods[modName]
        if runningVersion then
            if compareArrays(parseVersion(runningVersion), parseVersion(minimalVersion)) < 0 then
                local msg = "Dana is incompatible with '" .. modName .. "' version " .. runningVersion .. ". "
                msg = msg .. "Please update '" .. modName .. "' to at least v" .. minimalVersion .. "."
                error(msg)
            end
        end
    end,

    -- Runs a patch after performing version checks.
    --
    -- If installVersion is the current version in the save file:
    -- * if targetVersion <= installVersion: the patch is skipped.
    -- * if minSupportedVersion <= installVersion < targetVersion:
    --       the patch is applied, and installVersion is set to max(targetVersion, installedVersion).
    -- * if installVersion < minSupportedVersion: An error is thrown.
    --
    -- Args:
    -- * minSupportedVersion: Minimal version required for this patch to be applied.
    -- * targetVersion: Target version, obtained after application of this patch
    -- * callback: Function to call to apply the patch.
    --
    run = function(minSupportedVersion, targetVersion, callback)
        local installVersion = getInstalledVersion()
        local installArray = parseVersion(installVersion)
        local targetArray = parseVersion(targetVersion)
        if compareArrays(installArray, targetArray) < 0 then
            local minArray = parseVersion(minSupportedVersion)
            if compareArrays(minArray, installArray) > 0 then
                error("Migration from '" .. targetVersion .. "' failed. Minimum supported: '" .. minSupportedVersion .. "'. Installed: '" .. installVersion .. "'.")
            end

            callback()

            local newVersion = getInstalledVersion()
            if compareArrays(parseVersion(newVersion), targetArray) < 0 then
                global.Dana.version = targetVersion
                newVersion = targetVersion
            end
            log("Migration applied (source: '" .. installVersion .. "' / installed: '" .. newVersion .. "').")
        else
            log("Migration skipped (target: '" .. targetVersion .."' / installed: '" .. installVersion .. "').")
        end
    end,
}

-- Compares version arrays using lexicographic order.
--
-- Args:
-- * v1: A version array.
-- * v2: Another version array.
--
-- Returns: An integer (0 for equality, -1 if v1 < v2, 1 if v1 > v2).
--
compareArrays = function(v1, v2)
    local l1,l2 = #v1,#v2
    local minLen = math.min(l1,l2)
    local result = 0

    local i = 1
    while result == 0 and i <= minLen do
        local n1,n2 = v1[i],v2[i]
        if n1 < n2 then
            result = -1
        elseif n1 > n2 then
            result = 1
        end
        i = i + 1
    end
    if result == 0 then
        if l1 < l2 then
            result = -1
        elseif l1 > l2 then
            result = 1
        end
    end
    return result
end

-- Gets a string representing the currently installed version of Dana.
--
-- Returns: The version of the mod currently stored in the global table.
--
getInstalledVersion = function()
    return global.Dana.version or "0.1.0"
end

-- Parses a string representing a version into an array of integer.
--
-- Args:
-- * strVersion: String representing the version (must be "a.b.c.d...", with only positive integers).
--
-- Returns: An array of integers {a,b,c,d,...}.
--
parseVersion = function(strVersion)
    local result = {}
    for subStr in string.gmatch(strVersion, "([^%.]+)") do
        table.insert(result, tonumber(subStr))
    end
    return result
end

return Updater
