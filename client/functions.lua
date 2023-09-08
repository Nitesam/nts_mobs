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

---Targeting System
---@param distance number
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