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

local drawFromVertex
local drawToVertex
local runImpl

-- Utility class drawing TreeLink of the SimpleRenderer.
--
local SimpleTreeDrawer = ErrorOnInvalidRead.new{
    -- Renders a TreeLink object.
    --
    -- Args:
    -- * linkDrawer: SimpleLinkDrawer object to use.
    -- * treeLink: The TreeLink to render.
    --
    run = function(linkDrawer, treeLink)
        linkDrawer:setLinkCategoryIndex(treeLink.categoryIndex)
        linkDrawer.lineArgs.selectable = true

        local root = treeLink.tree
        local linkIndex = root.linkIndex
        linkDrawer:setSpritePath(linkIndex.symbol.spritePath)
        if linkIndex.isFromRoot then
            linkDrawer.drawSpriteAtSrc = false
            drawFromVertex(linkDrawer, root)
        else
            drawToVertex(linkDrawer, root)
        end
    end,
}

-- Renders a treeLinkNode object, with arrows going from the vertex to the edges.
--
-- Args:
-- * linkDrawer (modified): SimpleLinkDrawer to use to draw the links.
-- * tree: The treeLinkNode to render.
--
drawFromVertex = function(linkDrawer, tree)
    for subtree in pairs(tree.children) do
        drawFromVertex(linkDrawer, subtree)
    end

    linkDrawer:setFrom(tree.x, tree.y)
    for subtree in pairs(tree.children) do
        local subCount = subtree.childCount
        local drawExtra = (subCount == 0) or subtree.infoHint
        linkDrawer.makeTriangle = drawExtra
        linkDrawer.drawSpriteAtDest = drawExtra
        linkDrawer:setTo(subtree.x, subtree.y)

        local line = linkDrawer:draw()
        line.rendererType = "treeLinkNode"
        line.rendererIndex = subtree

        if subCount >= 2 then
            linkDrawer:drawCircle(false)
        end
    end
end

-- Renders a treeLinkNode object, with arrows going from the edges to the vertex.
--
-- Args:
-- * linkDrawer (modified): SimpleLinkDrawer to use to draw the links.
-- * tree: The treeLinkNode to render.
--
drawToVertex = function(linkDrawer, tree)
    for subtree in pairs(tree.children) do
        drawToVertex(linkDrawer, subtree)
    end

    linkDrawer:setTo(tree.x, tree.y)
    linkDrawer.makeTriangle = not rawget(tree, "parent") or tree.infoHint
    linkDrawer.drawSpriteAtDest = tree.infoHint
    for subtree in pairs(tree.children) do
        local subCount = subtree.childCount
        linkDrawer:setFrom(subtree.x, subtree.y)
        linkDrawer.drawSpriteAtSrc = (subCount == 0)
        local line = linkDrawer:draw()
        line.rendererType = "treeLinkNode"
        line.rendererIndex = subtree

        if subCount >= 2 then
            linkDrawer:drawCircle(true)
        end
    end
end

return SimpleTreeDrawer
