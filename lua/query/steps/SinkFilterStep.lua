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

-- Library to filter indirect sinks from a crafting graph.
--
local SinkFilterStep = ErrorOnInvalidRead.new{
    -- Runs the indirect sink filter on a graph.
    --
    -- Args:
    -- * query: AbstractQuery. Parameters to use.
    -- * force: Force. Database on which the query is run.
    -- * graph: DirectedHypergraph. Graph to modify.
    --
    run = function(query, force, graph)
        local MinFloat = -math.huge
        local minThreshold = rawget(query.sinkParams, "indirectThreshold")
        if minThreshold then
            local checkedThresholds = {}
            local cacheThresholds = force.prototypes.sinkCache.indirectThresholds
            if query.sinkParams.filterNormal then
                checkedThresholds[cacheThresholds.normal] = true
            end
            if query.sinkParams.filterRecursive then
                checkedThresholds[cacheThresholds.recursive] = true
            end
            if next(checkedThresholds) then
                local removed = {}
                for edgeIndex in pairs(graph.edges) do
                    local score = MinFloat
                    for map in pairs(checkedThresholds) do
                        score = math.max(score, rawget(map, edgeIndex) or MinFloat)
                    end
                    if score >= minThreshold then
                        removed[edgeIndex] = true
                    end
                end
                for edgeIndex in pairs(removed) do
                    graph:removeEdgeIndex(edgeIndex)
                end
            end
        end
    end,
}

return SinkFilterStep
