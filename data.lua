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

selectionTool = {
    type = "selection-tool",
    name = "dana-select",
    alt_selection_color = {
        r = 0,
        g = 0.5,
        b = 0,
    },
    selection_color = {
        r = 0,
        g = 0.5,
        b = 0,
    },
    alt_selection_mode = {"nothing"},
    selection_mode = {"nothing"},
    selection_cursor_box_type = "copy",
    alt_selection_cursor_box_type = "copy",
    flags = {"not-stackable"},
    stack_size = 1,
    icon = "__base__/graphics/icons/blueprint.png",
    icon_mipmaps = 4,
    icon_size = 64,
}

shortcut = {
    type = "shortcut",
    name = "dana-select-shortcut",
    action = "create-blueprint-item",
    item_to_create = "dana-select",
    icon = {
        filename = "__base__/graphics/icons/shortcut-toolbar/mip/new-blueprint-x32-white.png",
        flags = {
            "gui-icon",
        },
        mipmap_count = 2,
        priority = "extra-high-no-scale",
        scale = 0.5,
        size = 32,
    },
}

data:extend({selectionTool, shortcut})
