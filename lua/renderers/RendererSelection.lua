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

local ErrorOnInvalidRead = require("lua/containers/ErrorOnInvalidRead")

-- Class holding the results of a selection request from a renderer object.
--
-- Fields:
-- * edges: Set of edge indices from the input graph.
-- * link: Set of TreeLink node from the layout.
-- * vertices: Set of vertex indices from the input graph.
--
local RendererSelection = ErrorOnInvalidRead.new{
    -- Creates a new RendererSelection object.
    --
    -- Returns: the new RendererSelection object.
    --
    new = function()
        return ErrorOnInvalidRead.new{
            edges = ErrorOnInvalidRead.new(),
            links = ErrorOnInvalidRead.new(),
            vertices = ErrorOnInvalidRead.new(),
        }
    end,
}

return RendererSelection
