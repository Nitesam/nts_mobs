local zoneTrianglesCache = {}

local function getZoneTriangles(index, points)
    if not zoneTrianglesCache[index] then
        local centroid = getCentroid(points)
        local triangles = precomputePolygonTriangles(points, centroid)
        local borderDistance = Config.Mob.Zone[index].spawnBorderDistance or 10

        zoneTrianglesCache[index] = {
            triangles = triangles,
            borderDistance = borderDistance,
            points = points
        }
        Debug("Precomputed " .. #triangles .. " triangles for zone " .. index)
    end

    return zoneTrianglesCache[index].triangles, 
           zoneTrianglesCache[index].borderDistance,
           zoneTrianglesCache[index].points
end

function GetRandomPoints(index, points, count)
    local triangles, borderDistance, polygonPoints = getZoneTriangles(index, points)
    local generatedPoints = {}
    local maxAttempts = 20
    local generated = 0

    for i = 1, count do
        local point
        local attempts = 0

        while attempts < maxAttempts do
            attempts = attempts + 1
            point = getRandomPointInPolygon(triangles)

            if not isPointNearPolygonBorder(point.x, point.y, polygonPoints, borderDistance) then
                break
            end
        end

        if attempts >= maxAttempts then
            Debug("Warning: Could not find point far from border after " .. maxAttempts .. " attempts for zone " .. index)
        end

        local retval, groundZ = GetGroundZFor_3dCoord(point.x, point.y, point.z + 50.0, true)
        if retval then 
            point = vec3(point.x, point.y, groundZ + 0.5)
        end

        generated = generated + 1
        generatedPoints[generated] = point

        if i % 10 == 0 then Wait(0) end
    end

    Debug(generated, "points added for zone", index)
    return generatedPoints
end

function GetPlayers(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players, myPlayer = {}, PlayerId()

    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)

        if DoesEntityExist(ped) and ((onlyOtherPlayers and player ~= myPlayer) or not onlyOtherPlayers) then
            if returnKeyValue then
                players[player] = ped
            else
                players[#players + 1] = returnPeds and ped or player
            end
        end
    end

    return players
end

function getClosestPlayerToMob(mob)
    local closestDistance, closestPlayer = -1, -1
    local pos = GetEntityCoords(mob)

    for player, ped in pairs(GetPlayers(false, true, true)) do
        local distance = #(pos - GetEntityCoords(ped))

        if closestDistance == -1 or closestDistance > distance then
            closestPlayer = player
            closestDistance = distance
        end
    end

    return closestPlayer, closestDistance
end

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot(0)
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination =
    {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local shapeTest = StartExpensiveSynchronousShapeTestLosProbe(
        cameraCoord.x, cameraCoord.y, cameraCoord.z,
        destination.x, destination.y, destination.z,
        -1, cache.ped, 0
    )
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(shapeTest)
    return hit, endCoords, entityHit
end