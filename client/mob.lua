local init, ready, zoneMob = false, false, {}

local function getRandomPoints(indice, points, count)
    local centroid = getCentroid(points)
    local radius = getMinRadius(centroid, points)
    local points = {}

    for i = 1, count do
        local point = getRandomPoint(centroid, radius)
        while not zoneMob[indice].poly:contains(point) do
            Wait(25)
            point = getRandomPoint(centroid, radius)
        end

        table.insert(points, point)
    end
    Debug(#points, "added")
    return points
end

local function initialize()
    if not init then
        init = true

        for k, v in pairs(Config.Mob.Zone) do
            Debug("Initializing " .. k .. "...")

            zoneMob[k] = {}
            zoneMob[k].poly = lib.zones.poly({
                points = v.pos,
                thickness = 4,
                debug = v.debug,
                inside = function() end,
                onEnter = function() end,
                onExit = function() end
            })


            zoneMob[k].randomPoints = getRandomPoints(k, v.pos, 100)
        end

        for k,v in pairs(Config.Mob.MobType) do
            RequestAnimSet(v.movClipset)
	        Wait(10)
        end

        ready = true
    end
end

RegisterNetEvent("nts_mobs:doThingMob")
AddEventHandler("nts_mobs:doThingMob", function(zona, netId, mobType)
    while not ready do Wait(10) end

    local mob, mobType_C, time = NetworkGetEntityFromNetworkId(netId), Config.Mob.MobType[mobType], 5000
    Debug(zona, zoneMob[zona] and true or false, netId, mob)

    if DoesEntityExist(mob) then
        StopPedSpeaking(mob,true)
        DisablePedPainAudio(mob, true)
        TaskSetBlockingOfNonTemporaryEvents(mob, true)
        SetPedCombatAttributes(mob, 46, true)
        SetPedFleeAttributes(mob, 0, 0)
        SetBlockingOfNonTemporaryEvents(mob, true)


        while NetworkGetEntityOwner(mob) == cache.playerId do
            local nearPlayer, nearPlayerDistance = getClosestPlayerToMob(mob)
            if GetPedMovementClipset(mob) ~= GetHashKey(mobType_C.movClipset) then
                SetPedMovementClipset(mob, mobType_C.movClipset, 1.0)

                Debug("Mov clipset changed to " .. mobType_C.movClipset .. " for " .. netId)
            end

            if nearPlayerDistance <= mobType_C.visualRange then
                if not GetIsTaskActive(mob, 233) then
                    TaskGotoEntityAiming(mob, GetPlayerPed(nearPlayer), 2.0, 25.0)
                end

                time = 1000
            else
                if (GetIsTaskActive(mob, 15) and not GetIsTaskActive(mob, 35)) or GetIsTaskActive(mob, 233) then
                    local randCoords = zoneMob[zona].randomPoints[math.random(1, 100)]

                    ClearPedTasks(mob)
                    TaskGoToCoordAnyMeans(mob, randCoords.x, randCoords.y, randCoords.z, 1.0, 0, 0, 786603, 0xbf800000)

                    Debug(netId .. " wasn't doing anything, so i made him walking")
                end

                time = 5000
            end

            Citizen.Wait(time)
        end

        TriggerServerEvent("nts_mobs:lostOwnership", zona, netId)
    end
end)

if Config.Debug then
    RegisterCommand("movClipset", function (source, args, raw)
        RequestAnimSet(args[1])
        Wait(500)
        SetPedMovementClipset(cache.ped, args[1], 1.0)
    end, false)

    RegisterCommand("checkZoneMob", function (source, args, raw)
        for k, v in pairs(ZONE_TAB) do
            print(k, v.active)
        end
    end, false)
end

if GetResourceState("esx") == "started" then
    RegisterNetEvent("esx:playerLoaded")
    AddEventHandler("esx:playerLoaded", function()
        initialize()
    end)

    Citizen.CreateThread(function()
        if ESX.PlayerLoaded then
            initialize()
        end
    end)
else
    AddEventHandler("playerSpawned", function(spawnInfo)
        initialize()
        Debug("Currently Spawned with Info\n" .. json.encode(spawnInfo))
    end)
end
