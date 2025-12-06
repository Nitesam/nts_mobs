G_MOB, ZONE_TAB = {}, {}

local ZONE_EMPTY_TIMEOUT = Config.ZoneEmptyTimeout or 60
local ZONE_ENTRY_COOLDOWN = Config.ZoneEntryCooldown or 5
local playerZoneCooldown = {}


local spawnQueue = {}               -- { [zoneIndex] = { { mobType, spawnpoint_id, coords, retryCount }, ... } }
local SPAWN_RETRY_INTERVAL = 1000   -- ms
local MAX_SPAWN_RETRIES = 60        -- dopo 60 tentativi (60 secondi) abbandona

local respawnQueue = {}             -- { [zoneIndex] = { { spawnpoint_id, respawnAt }, ... } }

for k, v in pairs(Config.Mob.Zone) do
    ZONE_TAB[k] = {
        pos = v.pos,
        entities = {},
        active = 0,
        initialized = false,
        running = false,
        playersInside = {},
        lastPlayerLeft = 0,
        spawnPoints = {},
        currentSpawnpointCounter = 0,
        pendingSpawns = 0
    }
    spawnQueue[k] = {}
    respawnQueue[k] = {}
end

--- Applica le variazioni dei componenti al ped
---@param ped number Entity handle del ped
---@param mobConfig table Configurazione del mob da Config.Mob.MobType
local function ApplyPedComponents(ped, mobConfig)
    if not ped or not DoesEntityExist(ped) then return end
    if not mobConfig or not mobConfig.components then return end
    
    for componentId, componentData in pairs(mobConfig.components) do
        if componentData then
            local drawable = componentData.drawable or 0
            local texture = componentData.texture or 0
            local palette = componentData.palette or 0
            
            SetPedComponentVariation(ped, componentId, drawable, texture, palette)
            Debug(string.format("^2[PED COMPONENT] Applied component %d: drawable=%d, texture=%d, palette=%d^7", 
                componentId, drawable, texture, palette))
        end
    end
end

local function CreateServerPed(model, _x, _y, _z, _h, mobConfig)
    local ped = CreatePed(1, model, _x, _y, _z, _h, true, true)
    local retry = 0
    while not DoesEntityExist(ped) and retry < 50 do
        retry = retry + 1
        Citizen.Wait(10)
    end
    
    if not DoesEntityExist(ped) then return nil end
    if mobConfig then
        if mobConfig.randomComponents then
            SetPedRandomComponentVariation(ped, true)
        else
            ApplyPedComponents(ped, mobConfig)
        end
    end
    
    return ped
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

--- Verifica se un ped spawnato ha un network ID valido (client in range)
---@param ped number
---@return boolean, number|nil netId
local function validateSpawnedPed(ped)
    if not ped or not DoesEntityExist(ped) then
        return false, nil
    end
    
    local netId = NetworkGetNetworkIdFromEntity(ped)
    if not netId or netId == 0 then
        return false, nil
    end
    
    return true, netId
end

--- Aggiunge un mob alla coda di spawn
---@param zoneIndex string
---@param mobType string
---@param spawnpoint_id number
---@param coords vector3
local function queueMobSpawn(zoneIndex, mobType, spawnpoint_id, coords)
    table.insert(spawnQueue[zoneIndex], {
        mobType = mobType,
        spawnpoint_id = spawnpoint_id,
        coords = coords,
        retryCount = 0,
        queuedAt = os.time()
    })
    ZONE_TAB[zoneIndex].pendingSpawns = ZONE_TAB[zoneIndex].pendingSpawns + 1
    Debug(string.format("^3[QUEUE] Mob queued for zone %s | Type: %s | Spawnpoint: %d | Queue size: %d^7", 
        zoneIndex, mobType, spawnpoint_id, #spawnQueue[zoneIndex]))
end

--- Rimuove un elemento dalla coda
---@param zoneIndex string
---@param queueIndex number
local function removeFromQueue(zoneIndex, queueIndex)
    table.remove(spawnQueue[zoneIndex], queueIndex)
    ZONE_TAB[zoneIndex].pendingSpawns = math.max(0, ZONE_TAB[zoneIndex].pendingSpawns - 1)
end


local Inv = exports.core_inventory
local function registerAndInitInventory(mobConfig, zone, netId)
    local stashId = zone .. "-mob-".. netId

    Inv:openInventory(nil, stashId, 'stash', nil, nil, false, nil, true)
    Inv:clearInventory(stashId)

    for k,v in pairs(GenerateLootForMob(mobConfig)) do local res = Inv:addItem(stashId, v.item, v.quantity) --[[print(tostring(res) .. " for " .. v.item .. " x" .. v.quantity)]] end
end

--- Tenta di spawnare un mob dalla coda
---@param zoneIndex string
---@param queueIndex number
---@param queuedMob table
---@return boolean success
local function trySpawnFromQueue(zoneIndex, queueIndex, queuedMob)
    local zoneIndex = zoneIndex
    if not zoneIndex then
        return print("^1[QUEUE ERROR] zoneIndex is nil for " .. json.encode(queuedMob) .. "^7")
    end
    
    local mobConfig = Config.Mob.MobType[queuedMob.mobType]
    if not mobConfig then
        Debug("^1[QUEUE ERROR] Invalid mob type: " .. tostring(queuedMob.mobType) .. "^7")
        removeFromQueue(zoneIndex, queueIndex)
        return false
    end
    
    local coords = queuedMob.coords
    local spawnedPed = CreateServerPed(mobConfig.ped, coords.x, coords.y, coords.z, 0.0, mobConfig)
    
    if not spawnedPed then
        queuedMob.retryCount = queuedMob.retryCount + 1
        Debug(string.format("^3[QUEUE] Spawn failed (no ped), retry %d/%d^7", queuedMob.retryCount, MAX_SPAWN_RETRIES))
        return false
    end
    

    local isValid, netId = validateSpawnedPed(spawnedPed)
    if not isValid then
        DeleteEntity(spawnedPed)
        queuedMob.retryCount = queuedMob.retryCount + 1
        
        if queuedMob.retryCount % 10 == 0 then
            Debug(string.format("^3[QUEUE] No client in range for spawn, retry %d/%d^7", queuedMob.retryCount, MAX_SPAWN_RETRIES))
        end
        
        return false
    end
    
    FreezeEntityPosition(spawnedPed, true)

    registerAndInitInventory(mobConfig, zoneIndex, netId)
    
    ZONE_TAB[zoneIndex].entities[netId] = {
        ped = spawnedPed,
        owner = NetworkGetEntityOwner(spawnedPed) or -1,
        type = queuedMob.mobType,
        diedTime = 0,
        spawnpoint_id = queuedMob.spawnpoint_id,
        lootable = false,
        spawnCoords = coords
    }

    Entity(spawnedPed).state.lootable = false
    Entity(spawnedPed).state.mobType = queuedMob.mobType
    Entity(spawnedPed).state.spawnpoint_id = queuedMob.spawnpoint_id
    Entity(spawnedPed).state.zoneIndex = zoneIndex

    ZONE_TAB[zoneIndex].active = ZONE_TAB[zoneIndex].active + 1
    removeFromQueue(zoneIndex, queueIndex)
    
    Debug(string.format("^2[QUEUE SUCCESS] Mob spawned from queue | NetId: %d | Zone: %s | Retries: %d^7", 
        netId, zoneIndex, queuedMob.retryCount))
    
    return true
end

--- Aggiunge un respawn alla coda
---@param zoneIndex string
---@param spawnpoint_id number
local function queueRespawn(zoneIndex, spawnpoint_id)
    local respawnDelay = Config.Mob.Zone[zoneIndex].newSpawnTime or 30
    local respawnAt = os.time() + respawnDelay
    
    table.insert(respawnQueue[zoneIndex], {
        spawnpoint_id = spawnpoint_id,
        respawnAt = respawnAt
    })
    
    Debug(string.format("^3[RESPAWN QUEUE] Added respawn for zone %s | Spawnpoint: %d | In: %ds^7", 
        zoneIndex, spawnpoint_id, respawnDelay))
end

--- Thread per processare la coda di respawn di una zona
---@param zoneIndex string
local function startRespawnQueueThread(zoneIndex)
    Citizen.CreateThread(function()
        Debug("^2[RESPAWN QUEUE] Starting respawn queue thread for zone " .. zoneIndex .. "^7")
        
        while ZONE_TAB[zoneIndex].running do
            local queue = respawnQueue[zoneIndex]
            local now = os.time()
            
            if #queue > 0 then
                local i = 1
                while i <= #queue do
                    local item = queue[i]
                    
                    if now >= item.respawnAt then
                        Debug(string.format("^2[RESPAWN QUEUE] Processing respawn for zone %s | Spawnpoint: %d^7", 
                            zoneIndex, item.spawnpoint_id))
                        extractMob(zoneIndex, item.spawnpoint_id)
                        table.remove(queue, i)
                    else
                        i = i + 1
                    end
                end
            end
            
            Citizen.Wait(1000)
        end
        
        local remaining = #respawnQueue[zoneIndex]
        if remaining > 0 then
            Debug(string.format("^3[RESPAWN QUEUE] Zone %s stopped, clearing %d pending respawns^7", zoneIndex, remaining))
            respawnQueue[zoneIndex] = {}
        end
        
        Debug("^3[RESPAWN QUEUE] Respawn queue thread stopped for zone " .. zoneIndex .. "^7")
    end)
end

--- Thread per processare la coda di spawn di una zona
---@param zoneIndex string
local function startSpawnQueueThread(zoneIndex)
    Citizen.CreateThread(function()
        Debug("^2[QUEUE] Starting spawn queue thread for zone " .. zoneIndex .. "^7")
        local zoneIndex = zoneIndex
        while ZONE_TAB[zoneIndex].running do
            local queue = spawnQueue[zoneIndex]
            
            if #queue > 0 then
                local i = 1
                while i <= #queue do
                    local queuedMob = queue[i]
                    
                    if queuedMob.retryCount >= MAX_SPAWN_RETRIES then
                        Debug(string.format("^1[QUEUE] Mob spawn abandoned after %d retries | Zone: %s^7", 
                            queuedMob.retryCount, zoneIndex))
                        removeFromQueue(zoneIndex, i)
                    else
                        local success = trySpawnFromQueue(zoneIndex, i, queuedMob)
                        if success then
                        else
                            i = i + 1
                        end
                    end

                    Citizen.Wait(50)
                end
            end
            
            Citizen.Wait(SPAWN_RETRY_INTERVAL)
        end
        
        local remaining = #spawnQueue[zoneIndex]
        if remaining > 0 then
            Debug(string.format("^3[QUEUE] Zone %s stopped, clearing %d pending spawns^7", zoneIndex, remaining))
            spawnQueue[zoneIndex] = {}
            ZONE_TAB[zoneIndex].pendingSpawns = 0
        end
        
        Debug("^3[QUEUE] Spawn queue thread stopped for zone " .. zoneIndex .. "^7")
    end)
end

-- Nuova versione di spawnMob che usa la coda
local function spawnMob(index, mobType, try, spawnpoint_id)
    if not spawnpoint_id then
        ZONE_TAB[index].currentSpawnpointCounter = (ZONE_TAB[index].currentSpawnpointCounter + 1) % #ZONE_TAB[index].spawnPoints
        if ZONE_TAB[index].currentSpawnpointCounter == 0 then
            ZONE_TAB[index].currentSpawnpointCounter = 1
        end
        spawnpoint_id = ZONE_TAB[index].currentSpawnpointCounter
    end

    local coords = getRandomSpawnCoords(index, spawnpoint_id)
    if not coords then
        print("^1NTS_MOBS | CRITICAL ERROR | ^2No spawn points available for Zone " .. index .. ", cannot spawn mob.^7")
        return
    end

    queueMobSpawn(index, mobType, spawnpoint_id, coords)
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

    for netId, mobData in pairs(ZONE_TAB[index].entities) do
        if DoesEntityExist(mobData.ped) then
            DeleteEntity(mobData.ped)
        end
    end

    ZONE_TAB[index].entities = {}
    ZONE_TAB[index].active = 0
    ZONE_TAB[index].running = false
    ZONE_TAB[index].initialized = false
    ZONE_TAB[index].spawnPoints = {}
    ZONE_TAB[index].pendingSpawns = 0
    spawnQueue[index] = {}
    respawnQueue[index] = {}

    Debug("^1[nts_mobs] - ^0Zone " .. index .. " cleared and closed.")
end

-- @param zone: string; netId: int; giveDrop: int (should be source id of player receiver)
local function removeMob(zone, netId, deathCoords)
    local mobData = ZONE_TAB[zone].entities[netId]
    if not mobData then return end

    local saved_spawnpoint = mobData.spawnpoint_id
    ZONE_TAB[zone].entities[netId] = nil
    ZONE_TAB[zone].active -= 1

    if deathCoords then
        for k,v in pairs(ZONE_TAB[zone].playersInside) do
            TriggerClientEvent("nts_mobs:client:remove_mob", k, zone, netId, deathCoords)
        end
    end

    if ZONE_TAB[zone].running then
        queueRespawn(zone, saved_spawnpoint)
    end
end

local function startZoneThread(index)
    if ZONE_TAB[index].running then return end

    ZONE_TAB[index].running = true
    Debug("^2[nts_mobs] - ^0Starting thread for zone " .. index)

    startSpawnQueueThread(index)
    startRespawnQueueThread(index)

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

            if Config.Debug and #spawnQueue[index] > 0 then
                Debug(string.format("^3[ZONE %s] Active: %d | Queued: %d^7", index, ZONE_TAB[index].active, #spawnQueue[index]))
            end

            for k, mob in pairs(ZONE_TAB[index].entities) do
                if DoesEntityExist(mob.ped) then
                    local owner = NetworkGetEntityOwner(mob.ped)
                    local ownerDist = 999999
                    local mob_coords = GetEntityCoords(mob.ped)

                    if owner ~= -1 then
                        local ownerPed = GetPlayerPed(owner)
                        if ownerPed and DoesEntityExist(ownerPed) then
                            ownerDist = #(mob_coords - GetEntityCoords(ownerPed))
                        end
                    end
                    
                    if owner ~= -1 and GetEntityHealth(mob.ped) <= 0 then
                        if ownerDist <= 100.0 then
                            mob.diedTime += 1

                            if mob.diedTime >= Config.Mob.MobType[mob.type].tryBeforeRemoving then
                                removeMob(index, k, mob_coords)
                            else
                                if not mob.lootable then
                                    Entity(mob.ped).state.lootable = true
                                    mob.lootable = true
                                end
                            end
                        end
                    end
                else
                    Debug("^1Mob " .. k .. " does not exist anymore, removing from zone.^7")
                    removeMob(index, k, nil)
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

    --[[playerZoneCooldown[src] = playerZoneCooldown[src] or {}
    if playerZoneCooldown[src][zoneIndex] and (now - playerZoneCooldown[src][zoneIndex]) < ZONE_ENTRY_COOLDOWN then
        Debug("Player " .. src .. " zone entry cooldown active for " .. zoneIndex)
        return
    end
    playerZoneCooldown[src][zoneIndex] = now]]

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

    --[[playerZoneCooldown[src] = playerZoneCooldown[src] or {}
    playerZoneCooldown[src][zoneIndex] = now]]

    ZONE_TAB[zoneIndex].playersInside[src] = nil
    ZONE_TAB[zoneIndex].lastPlayerLeft = now
    Debug("Player " .. src .. " exited zone " .. zoneIndex)
end)

AddEventHandler("playerDropped", function(reason)
    local src = source
    --playerZoneCooldown[src] = nil

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
    local mob = ZONE_TAB[zoneIndex] and ZONE_TAB[zoneIndex].entities[netId]
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

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    for k, v in pairs(ZONE_TAB) do
        for _, b in pairs(v.entities) do
            if DoesEntityExist(b.ped) then
                DeleteEntity(b.ped)
                print("Deleting mob " .. tostring(b.ped) .. " from zone " .. k)
            end
        end
    end
    print("^1[nts_mobs] - ^0All mobs deleted on resource stop.")
end)

if not Config.Debug then return end
for k,v in pairs(GetAllPeds()) do -- DA RIMUOVERE IN PRODUCTION!!!!!!!!!!!!!!!!!!!!
    DeleteEntity(v)
end

RegisterCommand("print_mobs_exists", function(source, args, rawCommand)
    if source > 0 then return end
    print("---- MOB SPAWNED ENTITIES ----")
    for zoneIndex, zone in pairs(ZONE_TAB) do
        print("Zone " .. zoneIndex .. ":")
        for netId, mobData in pairs(zone.entities) do
            if DoesEntityExist(mobData.ped) then
                local owner = NetworkGetEntityOwner(mobData.ped)
                local owner_ped = GetPlayerPed(owner)

                print("  Mob NetId: " .. netId .. " | Ped: " .. tostring(mobData.ped) .. " | Type: " .. mobData.type .. owner ~= -1 and (" | Distance from owner: " .. 
                    #(GetEntityCoords(mobData.ped) - GetEntityCoords(owner_ped))))
            else
                print("  Mob NetId: " .. netId .. " | Ped: INVALID ENTITY | Type: " .. mobData.type)
            end
        end
    end
    print("---- END OF LIST ----")
end, false)