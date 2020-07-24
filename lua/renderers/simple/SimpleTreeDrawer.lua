-- This file is part of Dana.
-- Copyright (C) 2019,2020 Vincent Saulue-Laborde <vincent_saulue@hotmail.fr>
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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")
local SimpleConfig = require("lua/renderers/simple/SimpleConfig")

local runImpl

-- Utility class drawing TreeLink of the SimpleRenderer.
--
local SimpleTreeDrawer = ErrorOnInvalidRead.new{
    -- Makes common constructor arguments for the lines of links.
    --
    -- Returns: A partially filled table usable in Canvas:makeLine().
    --
    makeLinkLineArgs = function()
        return {
            draw_on_ground = true,
            width = SimpleConfig.LinkLineWitdh,
        }
    end,

    -- Renders a TreeLink object.
    --
    -- Args:
    -- * canvas: Canvas object on which to do the render.
    -- * treeLink: The TreeLink to render.
    --
    run = function(canvas, treeLink)
        local color = SimpleConfig.LinkCategoryToColor[treeLink.categoryIndex]
        runImpl(canvas, treeLink.tree, color)
    end,
}

-- Renders a treeLinkNode object.
--
-- Args:
-- * canvas: Canvas object on which to do the render.
-- * tree: The treeLinkNode to render.
-- * color: Color used to draw the link.
--
runImpl = function(canvas, tree, color)
    local from = {tree.x, tree.y}
    local lineArgs = SimpleTreeDrawer.makeLinkLineArgs()
    lineArgs.color = color
    lineArgs.from = from
    lineArgs.to = {}
    lineArgs.selectable = true

    local count = 0
    for subtree in pairs(tree.children) do
        count = count + 1
        lineArgs.to.x = subtree.x
        lineArgs.to.y = subtree.y
        local line = canvas:newLine(lineArgs)
        line.rendererType = "treeLinkNode"
        line.rendererIndex = subtree
        runImpl(canvas, subtree, color)
    end
    if rawget(tree, "parent") then
        count = count + 1
    end
    if count > 2 then
        canvas:newCircle{
            color = color,
            draw_on_ground = true,
            filled = true,
            radius = 0.125,
            target = from,
        }
    end
end

return SimpleTreeDrawer
