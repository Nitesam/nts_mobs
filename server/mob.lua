G_MOB, ZONE_TAB = {}, {}

local ZONE_EMPTY_TIMEOUT = Config.ZoneEmptyTimeout or 60
local ZONE_ENTRY_COOLDOWN = Config.ZoneEntryCooldown or 5
local playerZoneCooldown = {}

for k, v in pairs(Config.Mob.Zone) do
    ZONE_TAB[k] = {
        pos = v.pos,
        mob = {},
        active = 0,
        initialized = false,
        running = false,
        playersInside = {},
        lastPlayerLeft = 0,
        spawnPoints = {},
        currentSpawnpointCounter = 0
    }
end

local function requestZoneSpawnPoints(index, requestingPlayer)
    if not Config.Mob.Zone?[index]?.mobMax or Config.Mob.Zone[index].mobMax <= 0 then return false end
    local resp = lib.callback.await("nts_mobs:client:request_random_points", requestingPlayer, index, (Config.Mob.Zone[index].mobMax * 2) + 1)
    if resp and type(resp) == "table" and #resp > 0 then
        ZONE_TAB[index].spawnPoints = resp
        return true
    end

    return false
end

local function getRandomSpawnCoords(index, spawnpoint_id)
    local zone = ZONE_TAB[index]
    if not zone.spawnPoints or #zone.spawnPoints == 0 then return nil end
    return zone.spawnPoints[spawnpoint_id]
end

local function spawnMob(index, mobType, try, spawnpoint_id)
    if not spawnpoint_id then
        ZONE_TAB[index].currentSpawnpointCounter = (ZONE_TAB[index].currentSpawnpointCounter + 1) % #ZONE_TAB[index].spawnPoints
        spawnpoint_id = ZONE_TAB[index].currentSpawnpointCounter
    end

    local coords = getRandomSpawnCoords(index, spawnpoint_id)
    if not coords then
        print("No spawn points available for zone " .. index)
        return
    end

    print(mobType .. " spawning after " .. try + 1 .. " try.")

    Citizen.CreateThread(function()
        local spawnedPed = CreatePed(2, Config.Mob.MobType[mobType].ped, coords.x, coords.y, coords.z, 0.0, true, true)
        Citizen.Wait(100)

        if DoesEntityExist(spawnedPed) then
            local tempNet = NetworkGetNetworkIdFromEntity(spawnedPed)
            ZONE_TAB[index].mob[tempNet] = {ped = spawnedPed, owner = NetworkGetEntityOwner(spawnedPed) or -1, type = mobType, diedTime = 0, spawnpoint_id = spawnpoint_id}
            ZONE_TAB[index].active += 1

            Entity(spawnedPed).state.mobZone = index
            Entity(spawnedPed).state.mobType = mobType
            Entity(spawnedPed).state.spawnpoint_id = spawnpoint_id

            --[[if ZONE_TAB[index].mob[tempNet].owner ~= -1 then
                TriggerClientEvent("nts_mobs:client:control_mob", ZONE_TAB[index].mob[tempNet].owner, index, tempNet, mobType)
                print("Mob " .. tempNet .. " spawned on spawn number " .. spawnpoint_id .. " and assigned to owner " .. ZONE_TAB[index].mob[tempNet].owner .. ".")
            end]]
        else
            if try < 10 then
                spawnMob(index, mobType, try + 1, spawnpoint_id)
            end
        end
    end)
end

local function extractMob(index, spawnpoint_id)
    if not ZONE_TAB[index].running then return false end

    if ZONE_TAB[index].active < Config.Mob.Zone[index].mobMax then
        local chosen = pickRandomMob(Config.Mob.Zone[index].mobs)

        if chosen then
            spawnMob(index, chosen, 0, spawnpoint_id)
            return true
        end
    end

    return false
end

local function clearZone(index)
    Debug("^1[nts_mobs] - ^0Clearing zone " .. index)

    for netId, mobData in pairs(ZONE_TAB[index].mob) do
        if DoesEntityExist(mobData.ped) then
            DeleteEntity(mobData.ped)
        end
    end

    ZONE_TAB[index].mob = {}
    ZONE_TAB[index].active = 0
    ZONE_TAB[index].running = false
    ZONE_TAB[index].initialized = false
    ZONE_TAB[index].spawnPoints = {}

    Debug("^1[nts_mobs] - ^0Zone " .. index .. " cleared and closed.")
end

-- @param zone: string; netId: int; giveDrop: int (should be source id of player receiver)
local function removeMob(zone, netId, giveDrop)
    if ZONE_TAB[zone].mob[netId] then
        if DoesEntityExist(ZONE_TAB[zone].mob[netId].ped) then
            DeleteEntity(ZONE_TAB[zone].mob[netId].ped)

            if giveDrop then
                -- TO DO
            end
        end

        local saved_spawnpoint = ZONE_TAB[zone].mob[netId].spawnpoint_id
        ZONE_TAB[zone].mob[netId] = nil
        ZONE_TAB[zone].active -= 1

        if ZONE_TAB[zone].running then
            SetTimeout(Config.Mob.Zone[zone].newSpawnTime * 1000, function()
                if ZONE_TAB[zone].running then
                    Debug("New Mob Spawning Try in " .. zone .. " has been requested because timeout of removed one expired.")
                    extractMob(zone, saved_spawnpoint)
                end
            end)
        end
    end
end

local function startZoneThread(index)
    if ZONE_TAB[index].running then return end

    ZONE_TAB[index].running = true
    Debug("^2[nts_mobs] - ^0Starting thread for zone " .. index)

    Citizen.CreateThread(function()
        while ZONE_TAB[index].running do
            local playerCount = 0
            for _ in pairs(ZONE_TAB[index].playersInside) do
                playerCount = playerCount + 1
            end

            if playerCount == 0 then
                local timeSinceLastPlayer = os.time() - ZONE_TAB[index].lastPlayerLeft
                if ZONE_TAB[index].lastPlayerLeft > 0 and timeSinceLastPlayer >= ZONE_EMPTY_TIMEOUT then
                    clearZone(index)
                    break
                end
            end

            for k, v in pairs(ZONE_TAB[index].mob) do
                if DoesEntityExist(v.ped) then
                    local owner = NetworkGetEntityOwner(v.ped)

                    --[[if owner ~= v.owner then
                        Debug("Mob " .. k .. " Owner Changed from " .. v.owner .. " to " .. owner .. ".")

                        ZONE_TAB[index].mob[k].owner = owner
                        TriggerClientEvent("nts_mobs:client:control_mob", owner, index, k, v.type)
                    end]]

                    if owner ~= -1 and GetEntityHealth(v.ped) <= 0 then
                        ZONE_TAB[index].mob[k].diedTime += 1

                        if v.diedTime >= Config.Mob.MobType[ZONE_TAB[index].mob[k].type].tryBeforeRemoving then
                            Debug("Mob " .. k .. " Died and has been Removed.")
                            removeMob(index, k, nil)
                        else
                            Debug("Mob " .. k .. " Died and will be removed at next try.\nCurrent: " .. v.diedTime .. ".")
                        end
                    end
                end
            end

            Citizen.Wait(math.random(9000, 11000))
        end

        Debug("^3[nts_mobs] - ^0Thread for zone " .. index .. " stopped.")
    end)
end

local function initZone(index, requestingPlayer)
    if ZONE_TAB[index].initialized then return end

    ZONE_TAB[index].initialized = true
    Debug("^2[nts_mobs] - ^0Initializing zone " .. index)

    local success = requestZoneSpawnPoints(index, requestingPlayer)
    if not success then
        Debug("^1[nts_mobs] - ^0Failed to get spawn points for zone " .. index)
        ZONE_TAB[index].initialized = false
        return
    end

    startZoneThread(index)

    Wait(500)
    if ZONE_TAB[index].running and ZONE_TAB[index].active < Config.Mob.Zone[index].mobMax then
        for i = 1, Config.Mob.Zone[index].mobMax - ZONE_TAB[index].active do
            if not ZONE_TAB[index].running then break end
            extractMob(index)
            Wait(1)
        end
    end

    Debug("^2[nts_mobs] - ^0Zone " .. index .. " initialized with " .. ZONE_TAB[index].active .. " mobs.")
end

RegisterServerEvent("nts_mobs:server:playerEnterZone")
AddEventHandler("nts_mobs:server:playerEnterZone", function(zoneIndex)
    local src = source
    local now = os.time()

    if not ZONE_TAB[zoneIndex] then return end

    if ZONE_TAB[zoneIndex].playersInside[src] then
        Debug("Player " .. src .. " already inside zone " .. zoneIndex .. ", ignoring enter")
        return
    end

    playerZoneCooldown[src] = playerZoneCooldown[src] or {}
    if playerZoneCooldown[src][zoneIndex] and (now - playerZoneCooldown[src][zoneIndex]) < ZONE_ENTRY_COOLDOWN then
        Debug("Player " .. src .. " zone entry cooldown active for " .. zoneIndex)
        return
    end
    playerZoneCooldown[src][zoneIndex] = now

    ZONE_TAB[zoneIndex].playersInside[src] = true
    Debug("Player " .. src .. " entered zone " .. zoneIndex)

    if not ZONE_TAB[zoneIndex].initialized then
        initZone(zoneIndex, src)
    elseif not ZONE_TAB[zoneIndex].running then
        local success = requestZoneSpawnPoints(zoneIndex, src)
        if success then
            startZoneThread(zoneIndex)
            ZONE_TAB[zoneIndex].initialized = true
        end
    end
end)


RegisterServerEvent("nts_mobs:server:playerExitZone")
AddEventHandler("nts_mobs:server:playerExitZone", function(zoneIndex)
    local src = source
    local now = os.time()

    if not ZONE_TAB[zoneIndex] then return end

    if not ZONE_TAB[zoneIndex].playersInside[src] then
        Debug("Player " .. src .. " not inside zone " .. zoneIndex .. ", ignoring exit")
        return
    end

    playerZoneCooldown[src] = playerZoneCooldown[src] or {}
    playerZoneCooldown[src][zoneIndex] = now

    ZONE_TAB[zoneIndex].playersInside[src] = nil
    ZONE_TAB[zoneIndex].lastPlayerLeft = now
    Debug("Player " .. src .. " exited zone " .. zoneIndex)
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    playerZoneCooldown[src] = nil

    for zoneIndex, zone in pairs(ZONE_TAB) do
        if zone.playersInside[src] then
            zone.playersInside[src] = nil
            zone.lastPlayerLeft = os.time()
            Debug("Player " .. src .. " disconnected, removed from zone " .. zoneIndex)
        end
    end
end)

--[[RegisterServerEvent("nts_mobs:lostOwnership")
AddEventHandler("nts_mobs:lostOwnership", function(zoneIndex, netId)
    local mob = ZONE_TAB[zoneIndex] and ZONE_TAB[zoneIndex].mob[netId]
    if mob then
        mob.owner = NetworkGetEntityOwner(mob.ped)
        TriggerClientEvent("nts_mobs:client:control_mob", mob.owner, zoneIndex, netId, mob.type)
        Debug(source .. " told me that he lost the ownership, so i sent the mob task to the new owner [".. mob.owner .."]")
    end
end)]]

RegisterNetEvent("nts_mobs:server:playerDamage", function(target, net_mob, damage)
    local user_ped = GetPlayerPed(target)
    if not user_ped or not DoesEntityExist(user_ped) then return end

    local mob = NetworkGetEntityFromNetworkId(net_mob)
    if not mob or not DoesEntityExist(mob) then return end

    if #(GetEntityCoords(user_ped) - GetEntityCoords(mob)) <= 50.0 then
        SetEntityHealth(user_ped, GetEntityHealth(user_ped) - damage)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
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