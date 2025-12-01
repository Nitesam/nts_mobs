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
    local maxBorderAttempts = 20
    local maxMaterialAttempts = 10
    local zoneConfig = Config.Mob.Zone[index]
    local hasWhitelist = zoneConfig.whitelistedSoilTypes and next(zoneConfig.whitelistedSoilTypes)

    local pointsNeeded = count
    local totalAttempts = 0
    local maxTotalAttempts = count * (maxBorderAttempts + maxMaterialAttempts)

    while #generatedPoints < pointsNeeded and totalAttempts < maxTotalAttempts do
        totalAttempts = totalAttempts + 1

        local point
        local borderAttempts = 0

        while borderAttempts < maxBorderAttempts do
            borderAttempts = borderAttempts + 1
            point = getRandomPointInPolygon(triangles)

            if not isPointNearPolygonBorder(point.x, point.y, polygonPoints, borderDistance) then
                break
            end
        end

        if borderAttempts >= maxBorderAttempts then
            Debug("Warning: Could not find point far from border after " .. maxBorderAttempts .. " attempts for zone " .. index)
            goto continue
        end

        local retval, groundZ = GetGroundZFor_3dCoord(point.x, point.y, point.z + 100.0, true)
        if not retval then 
            Debug("Warning: GetGroundZFor_3dCoord failed at " .. point.x .. ", " .. point.y)
            goto continue
        end

        point = vec3(point.x, point.y, groundZ + 1.0)

        if hasWhitelist then
            local startZ = point.z + 5.0
            local endZ = point.z - 3.0
            local hit, _, _, _, material = lib.raycast.fromCoords(
                vec3(point.x, point.y, startZ),
                vec3(point.x, point.y, endZ),
                1,
                0
            )

            if Config.Debug then
                local debugPoint = point
                local debugMaterial = material
                Citizen.CreateThread(function()
                    local endTime = GetGameTimer() + 30000
                    while GetGameTimer() < endTime do
                        DrawLine(debugPoint.x, debugPoint.y, debugPoint.z + 5.0, debugPoint.x, debugPoint.y, debugPoint.z - 3.0, 255, 0, 0, 150)
                        qbx.drawText3d({
                            text = "Material: " .. tostring(debugMaterial),
                            coords = vec3(debugPoint.x, debugPoint.y, debugPoint.z + 1.0),
                            scale = 0.35,
                            font = 4,
                            color = vec4(255, 255, 255, 200),
                            disableDrawRect = false,
                            enableDropShadow = true,
                            enableOutline = true
                        })
                        Wait(0)
                    end
                end)
            end

            if not hit or not material or material == 0 then
                Debug("Warning: Raycast failed or material is 0 at " .. point.x .. ", " .. point.y)
                goto continue
            end

            if not zoneConfig.whitelistedSoilTypes[material] then
                Debug("Warning: Material " .. tostring(material) .. " not whitelisted at " .. point.x .. ", " .. point.y)
                goto continue
            end
        end

        generatedPoints[#generatedPoints + 1] = point
        if #generatedPoints % 5 == 0 then Wait(0) end

        ::continue::
    end

    if #generatedPoints < pointsNeeded then
        Debug("Warning: Only found " .. #generatedPoints .. "/" .. pointsNeeded .. " valid points for zone " .. index .. " after " .. totalAttempts .. " attempts")
    end

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
        if not IsPedDeadOrDying(ped, true) then
            local distance = #(pos - GetEntityCoords(ped))

            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = player
                closestDistance = distance
            end
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