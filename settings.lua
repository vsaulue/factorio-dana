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

-- Added for https://mods.factorio.com/mod/dana/discussion/5f38a575532359df0888b9fa.
Updater.assertModVersion(mods, "informatron", "0.1.12")

data:extend{
    {
        type = "bool-setting",
        name = "dana-enable-top-left-button",
        setting_type = "runtime-per-user",
        default_value = true,
    },
}
