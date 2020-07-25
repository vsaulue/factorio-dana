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
local SimpleLinkDrawer = require("lua/renderers/simple/SimpleLinkDrawer")

local runImpl

-- Utility class drawing TreeLink of the SimpleRenderer.
--
local SimpleTreeDrawer = ErrorOnInvalidRead.new{
    -- Renders a TreeLink object.
    --
    -- Args:
    -- * canvas: Canvas object on which to do the render.
    -- * treeLink: The TreeLink to render.
    --
    run = function(canvas, treeLink)
        local color = SimpleConfig.LinkCategoryToColor[treeLink.categoryIndex]
        local linkDrawer = SimpleLinkDrawer.new{
            canvas = canvas,
        }
        linkDrawer:setLinkCategoryIndex(treeLink.categoryIndex)
        linkDrawer.lineArgs.selectable = true
        runImpl(linkDrawer, treeLink.tree)
    end,
}

-- Renders a treeLinkNode object.
--
-- Args:
-- * linkDrawer (modified): SimpleLinkDrawer to use to draw the links.
-- * tree: The treeLinkNode to render.
--
runImpl = function(linkDrawer, tree)
    local count = 0
    for subtree in pairs(tree.children) do
        runImpl(linkDrawer, subtree)
        count = count + 1
    end

    linkDrawer:setFrom(tree.x, tree.y)
    for subtree in pairs(tree.children) do
        linkDrawer:setTo(subtree.x, subtree.y)
        local line = linkDrawer:draw()
        line.rendererType = "treeLinkNode"
        line.rendererIndex = subtree
    end

    if rawget(tree, "parent") then
        count = count + 1
    end
    if count > 2 then
        linkDrawer.canvas:newCircle{
            color = linkDrawer.lineArgs.color,
            draw_on_ground = true,
            filled = true,
            radius = 0.125,
            target = linkDrawer.lineArgs.from,
        }
    end
end

return SimpleTreeDrawer
