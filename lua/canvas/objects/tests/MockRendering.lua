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

local rendering = {
    destroy = function(id)
        id.type = "destroyed"
    end,

    draw_circle = function(initData)
        return {
            type = "circle",
            target = {
                x = initData.target.x,
                y = initData.target.y,
            },
            radius = initData.radius,
        }
    end,

    draw_line = function(initData)
        return {
            type = "line",
            from = {
                x = initData.from.x,
                y = initData.from.y,
            },
            to = {
                x = initData.to.x,
                y = initData.to.y,
            },
        }
    end,

    draw_rectangle = function(initData)
        return {
            type = "rectangle",
            left_top = {
                x = initData.left_top.x,
                y = initData.left_top.y,
            },
            right_bottom = {
                x = initData.right_bottom.x,
                y = initData.right_bottom.y,
            },
        }
    end,

    get_from = function(id)
        local result = nil
        if id.type == "line" then
            result = {
                position = id.from,
            }
        end
        return result
    end,

    get_left_top = function(id)
        local result = nil
        if id.type == "rectangle" then
            result = {
                position = id.left_top,
            }
        end
        return result
    end,

    get_radius = function(id)
        local result = nil
        if id.type == "circle" then
            result = id.radius
        end
        return result
    end,

    get_right_bottom = function(id)
        local result = nil
        if id.type == "rectangle" then
            result = {
                position = id.right_bottom,
            }
        end
        return result
    end,

    get_target = function(id)
        local result = nil
        if id.type == "circle" then
            result = {
                position = id.target,
            }
        end
        return result
    end,

    get_to = function(id)
        local result = nil
        if id.type == "line" then
            result = {
                position = id.to,
            }
        end
        return result
    end,
}

return rendering
