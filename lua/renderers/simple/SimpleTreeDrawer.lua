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

local makeLinkLineArgs
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
        local lineArgs = makeLinkLineArgs()
        lineArgs.color = color
        lineArgs.from = {}
        lineArgs.to = {}
        lineArgs.selectable = true
        runImpl(canvas, lineArgs, treeLink.tree)
    end,
}

makeLinkLineArgs = SimpleTreeDrawer.makeLinkLineArgs

-- Renders a treeLinkNode object.
--
-- Args:
-- * canvas: Canvas object on which to do the render.
-- * lineArgs (modified): Constructor arguments to use in Canvas:drawLine()
-- * tree: The treeLinkNode to render.
--
runImpl = function(canvas, lineArgs, tree)
    local count = 0
    for subtree in pairs(tree.children) do
        runImpl(canvas, lineArgs, subtree)
        count = count + 1
    end

    lineArgs.from.x = tree.x
    lineArgs.from.y = tree.y
    for subtree in pairs(tree.children) do
        lineArgs.to.x = subtree.x
        lineArgs.to.y = subtree.y
        local line = canvas:newLine(lineArgs)
        line.rendererType = "treeLinkNode"
        line.rendererIndex = subtree
    end

    if rawget(tree, "parent") then
        count = count + 1
    end
    if count > 2 then
        canvas:newCircle{
            color = lineArgs.color,
            draw_on_ground = true,
            filled = true,
            radius = 0.125,
            target = lineArgs.from,
        }
    end
end

return SimpleTreeDrawer
