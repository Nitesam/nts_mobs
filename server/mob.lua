G_MOB, ZONE_TAB = {}, {}

for k,v in pairs(Config.Mob.Zone) do
    ZONE_TAB[k] = {}
    ZONE_TAB[k].pos = v.pos
    ZONE_TAB[k].mob = {}
    ZONE_TAB[k].active = 0
end

local function generaCoordinateZona(indice)
    if ZONE_TAB[indice] then
        local cerchioInterno = getCentroid(ZONE_TAB[indice].pos)
        local raggioMinimo = getMinRadius(cerchioInterno, ZONE_TAB[indice].pos)

        Debug("Coordinates Internal Circle " .. json.encode(cerchioInterno), "Internal Radius " .. json.encode(raggioMinimo) .. ".")
        return getRandomPoint(cerchioInterno, raggioMinimo)
    end

    return false
end

local function spawnMob(indice, mobType, try)
    local coordinate = generaCoordinateZona(indice)
    if coordinate then
        Debug(mobType .. " spawning after " .. try + 1 .. " try.")

        local spawnedPed = CreatePed(2, Config.Mob.MobType[mobType].ped, coordinate.x, coordinate.y, coordinate.z, 0.0, true, true)
        Citizen.Wait(100)

        if DoesEntityExist(spawnedPed) then
            local tempNet = NetworkGetNetworkIdFromEntity(spawnedPed)
            ZONE_TAB[indice].mob[tempNet] = {ped = spawnedPed, owner = NetworkGetEntityOwner(spawnedPed) or -1, type = mobType, diedTime = 0}
            ZONE_TAB[indice].active += 1

            if ZONE_TAB[indice].mob[tempNet].owner ~= -1 then
                TriggerClientEvent("nts_mobs:doThingMob", ZONE_TAB[indice].mob[tempNet].owner, indice, tempNet, mobType)
            end
        end

    else
        if try < 10 then
            spawnMob(indice, mobType, try + 1)
        end
    end
end

local function extractMob(indice)
    if ZONE_TAB[indice].active < Config.Mob.Zone[indice].mobMax then
        local choosen = pickRandomMob(Config.Mob.Zone[indice].mobs)

        if choosen then
            spawnMob(indice, choosen, 0)
            return true
        end
    end

    return false
end

-- @param zona: string; netId: int; giveDrop: int (should be source id of player receiver)

local function removeMob(zona, netId, giveDrop)
    if ZONE_TAB[zona].mob[netId] then
        if DoesEntityExist(ZONE_TAB[zona].mob[netId].ped) then
            DeleteEntity(ZONE_TAB[zona].mob[netId].ped)

            if giveDrop then
                -- TO DO
            end
        end

        ZONE_TAB[zona].mob[netId]  = nil
        ZONE_TAB[zona].active -= 1

        SetTimeout(Config.Mob.Zone[zona].newSpawnTime * 1000, function()
            Debug("New Mob Spawning Try in " .. zona .. " has been requested because timeout of removed one expired.")
            extractMob(zona)
        end)
    end
end

local function initZona(indice)
    if ZONE_TAB[indice] and ZONE_TAB[indice].active < Config.Mob.Zone[indice].mobMax  then
        for i = 1, Config.Mob.Zone[indice].mobMax - ZONE_TAB[indice].active do
            extractMob(indice)
        end
    end

    Wait(2500)

    Citizen.CreateThread(function()
        while true do
            for k, v in pairs(ZONE_TAB[indice].mob) do
                if DoesEntityExist(v.ped) then
                    local owner = NetworkGetEntityOwner(v.ped)

                    if owner ~= v.owner then
                        Debug("Mob " .. k .. " Owner Changed from " .. v.owner .. " to " .. owner .. ".")

                        ZONE_TAB[indice].mob[k].owner = owner
                        TriggerClientEvent("nts_mobs:doThingMob", owner, indice, k, v.type)
                    end

                    if owner ~= -1 and GetEntityHealth(v.ped) <= 0 then
                        ZONE_TAB[indice].mob[k].diedTime += 1

                        if v.diedTime >= Config.Mob.MobType[ZONE_TAB[indice].mob[k].type].tryBeforeRemoving then
                            Debug("Mob " .. k .. " Died and has been Removed.")
                            removeMob(indice, k, nil)
                        else
                            Debug("Mob " .. k .. " Died and will be removed at sixth try.\nCurrent: " .. v.diedTime .. ".")
                        end
                    end
                end
            end


            Citizen.Wait(math.random(29000, 31000))
        end
    end)
end

Citizen.CreateThread(function ()
    while #GetPlayers() == 0 do Citizen.Wait(2000) end

    for k, _ in pairs(ZONE_TAB) do
        initZona(k)
        Debug("^2[nts_mobs] - ^0" .. k .. " Initialized.")
    end
end)

RegisterServerEvent("nts_mobs:lostOwnership")
AddEventHandler("nts_mobs:lostOwnership", function(indiceZona, netId)
    if ZONE_TAB[indiceZona].mob[netId] then
        ZONE_TAB[indiceZona].mob[netId].owner = NetworkGetEntityOwner(ZONE_TAB[indiceZona].mob[netId].ped)
        TriggerClientEvent("nts_mobs:doThingMob", ZONE_TAB[indiceZona].mob[netId].owner, indiceZona, netId, ZONE_TAB[indiceZona].mob[netId].type)
        Debug(source .. " told me that he lost the ownership, so i sent the mob task to the new owner [".. ZONE_TAB[indiceZona].mob[netId].owner .."]")
    end
end)

AddEventHandler("onResourceStop", function (resourceName)
    if GetCurrentResourceName() == resourceName then
        for k, v in pairs(ZONE_TAB) do
            for _, b in pairs(v.mob) do
                if DoesEntityExist(b.ped) then
                    DeleteEntity(b.ped)
                end
            end
        end
    end
end)


