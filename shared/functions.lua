local eTaskTypeIndex <const> = ETaskTypeIndex

local random = math.random
local glm = require 'glm'
local glm_distance2 = glm.distance2
local glm_dot = glm.dot
local glm_cross = glm.cross
local glm_length = glm.length

function isPointNearPolygonBorder(x, y, polygon, distance)
    local distanceSq = distance * distance
    local n = #polygon
    local point2 = vec2(x, y)

    for i = 1, n do
        local j = i == n and 1 or i + 1
        local p1, p2 = polygon[i], polygon[j]
        local a = vec2(p1.x, p1.y)
        local b = vec2(p2.x, p2.y)
        local ab = b - a
        local lenSq = glm_distance2(a, b)
        local t = lenSq > 0 and glm_dot(point2 - a, ab) / lenSq or 0
        if t < 0 then t = 0 elseif t > 1 then t = 1 end

        local nearest = a + ab * t
        local distSq = glm_distance2(point2, nearest)

        if distSq <= distanceSq then return true end
    end
    return false
end

function getCentroid(points)
    local n = #points
    local acc = vec3(0, 0, 0)
    for i = 1, n do
        acc = acc + points[i]
    end
    return acc / n
end

local function triangleArea(p1, p2, p3)
    return 0.5 * glm_length(glm_cross(p2 - p1, p3 - p1))
end

local function randomPointInTriangle(p1, p2, p3)
    local r1, r2 = random(), random()

    if r1 + r2 > 1 then
        r1 = 1 - r1
        r2 = 1 - r2
    end

    local r3 = 1 - r1 - r2

    return vec3(
        r1 * p1.x + r2 * p2.x + r3 * p3.x,
        r1 * p1.y + r2 * p2.y + r3 * p3.y,
        r1 * p1.z + r2 * p2.z + r3 * p3.z
    )
end
function precomputePolygonTriangles(polygon, centroid)
    local triangles = {}
    local totalArea = 0
    local n = #polygon

    for i = 1, n do
        local j = i == n and 1 or i + 1
        local p1, p2 = polygon[i], polygon[j]
        local area = triangleArea(centroid, p1, p2)

        triangles[i] = {
            p1 = centroid,
            p2 = p1,
            p3 = p2,
            area = area
        }
        totalArea = totalArea + area
    end

    local cumulative = 0
    for i = 1, n do
        cumulative = cumulative + triangles[i].area
        triangles[i].cumulativeProb = cumulative / totalArea
    end

    return triangles, totalArea
end

function getRandomPointInPolygon(triangles)
    local r = random()
    local low, high = 1, #triangles
    while low < high do
        local mid = math.floor((low + high) / 2)
        if triangles[mid].cumulativeProb < r then
            low = mid + 1
        else
            high = mid
        end
    end
    local tri = triangles[low]
    return randomPointInTriangle(tri.p1, tri.p2, tri.p3)
end

function DebugPedTask(ped)
    local tCount = 0

    for k,v in pairs(eTaskTypeIndex) do
        if GetIsTaskActive(ped, k) then
            tCount += 1
            print("^1Executing: [".. k .."] - " .. v)
        end
    end

    if tCount == 0 then
        print("No Task Executed by " .. ped .. "^7")
    else
        print("Total Task Executed: " .. tCount .. "^7")
    end
end

Debug = function (...) if Config.Debug then print(...) end end

if not IsDuplicityVersion() then
    exports("DebugPedTask", DebugPedTask)

    if Config.Debug then
        function Target(distance)
        while true do
            local casterCoords = GetEntityCoords(cache.ped)
            local hit, endCoords, entityHit = RayCastGamePlayCamera(50.0)

            if hit and IsEntityAPed(entityHit) and not IsEntityDead(entityHit) and entityHit ~= cache.ped then
                local entityCoord = GetEntityCoords(entityHit)

                if #(casterCoords - entityCoord) < distance then
                    DrawMarker(
                        3, entityCoord.x, entityCoord.y, entityCoord.z + 1.2,
                        0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.8, 0.5, 0, 255, 0, 100,
                        false, true, 2, false, nil, nil, false
                    )

                    if IsControlJustReleased(0, 38) then
                        return entityHit
                    end
                else
                    DrawMarker(
                        3, entityCoord.x, entityCoord.y, entityCoord.z + 1.2,
                        0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.8, 0.5, 255, 0, 0, 100,
                        false, true, 2, false, nil, nil, false
                    )
                end
            elseif endCoords then
                DrawMarker(
                    28, endCoords.x, endCoords.y, endCoords.z,
                    0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.1, 0.1, 0.1, 255, 0, 0, 100,
                    false, true, 2, false, nil, nil, false
                )
            end

            if IsControlJustPressed(0, 38) and not entityHit or IsControlJustPressed(0, 177) then
                return
            end

            Wait(0)
        end
    end

        RegisterCommand("task", function (source, args, raw)
            local ped = Target(50)

            if ped then
                DebugPedTask(ped)
            end
        end, false)
    end
end