local DO_NOTHING = 15
local TASK_WANDER = 222
local TASK_GO_TO_COORD_ANY_MEANS = 224
local TASK_SMART_FLEE = 218
local MOTION_STATE_RUNNING = -530524

-- ============================================
-- SISTEMA CENTRALIZZATO DI CONTROLLO MOB
-- ============================================

CONTROLLED_MOBS = {}          -- Tabella dei mob controllati
local controlThreadActive = false  -- Flag stato thread
local THREAD_TICK_RATE = 50        -- ms - frequenza base del thread
local closestControlledMobNetId = nil  -- NetId del mob controllato più vicino (per debug)

local MOB_STATE <const> = {
    IDLE = 1,
    WANDERING = 2,
    CHASING = 3,
    ATTACKING = 4,
    FLEEING = 5,
    COOLDOWN = 6
}

local MOB_STATE_NAMES = {
    [1] = "IDLE",
    [2] = "WANDERING",
    [3] = "CHASING",
    [4] = "ATTACKING",
    [5] = "FLEEING",
    [6] = "COOLDOWN"
}

-- ============================================
-- DEBUG FUNCTIONS
-- ============================================

--- Debug solo per il mob più vicino
---@param netId number Network ID del mob
---@param ... any Messaggi da stampare
local function DebugMob(netId, ...)
    if not Config.Debug then return end
    if netId ~= closestControlledMobNetId then return end

    local args = {...}
    local message = "[MOB DEBUG #" .. netId .. "] "
    for i, v in ipairs(args) do
        message = message .. tostring(v) .. " "
    end
    print(message)
end

--- Debug cambio stato del mob
---@param netId number
---@param oldState number
---@param newState number
local function DebugStateChange(netId, oldState, newState)
    if oldState ~= newState then
        DebugMob(netId, "State:", MOB_STATE_NAMES[oldState] or "?", "->", MOB_STATE_NAMES[newState] or "?")
    end
end

--- Trova il mob controllato più vicino al giocatore
---@return number|nil netId del mob più vicino
local function findClosestControlledMob()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local closestNetId = nil
    local closestDistance = math.huge

    for netId, mobData in pairs(CONTROLLED_MOBS) do
        if DoesEntityExist(mobData.mob) then
            local mobCoords = GetEntityCoords(mobData.mob)
            local distance = #(playerCoords - mobCoords)
            if distance < closestDistance then
                closestDistance = distance
                closestNetId = netId
            end
        end
    end

    return closestNetId
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function getControlledMobCount()
    local count = 0
    for _ in pairs(CONTROLLED_MOBS) do
        count = count + 1
    end
    return count
end

--- Configures mob behavior attributes (audio, combat, flee)
---@param mob number Entity handle
local function configureMobBehavior(mob)
    StopPedSpeaking(mob, false)
    DisablePedPainAudio(mob, false)
    TaskSetBlockingOfNonTemporaryEvents(mob, true)
    SetPedCombatAttributes(mob, 46, true)
    SetPedFleeAttributes(mob, 0, 0)
    SetBlockingOfNonTemporaryEvents(mob, true)
end

--- Ensures mob has the correct movement clipset applied
---@param mob number Entity handle
---@param mobConfig table Mob type configuration
---@param netId number Network ID for debug
local function ensureMovementClipset(mob, mobConfig, netId)
    local expectedClipset = GetHashKey(mobConfig.movClipset)
    if GetPedMovementClipset(mob) ~= expectedClipset then
        SetPedMovementClipset(mob, mobConfig.movClipset, 1.0)
        DebugMob(netId, "Applied movement clipset:", mobConfig.movClipset)
    end
end

--- Verifica se il mob non sta facendo nulla (completamente fermo)
---@param mob number Entity handle
---@return boolean isIdle
local function isMobIdle(mob)
    return GetIsTaskActive(mob, DO_NOTHING)
end

--- Verifica se il mob sta wanderando
---@param mob number Entity handle
---@return boolean isWandering
local function isMobWandering(mob)
    return GetIsTaskActive(mob, TASK_WANDER) or GetIsTaskActive(mob, TASK_GO_TO_COORD_ANY_MEANS)
end

--- Pulisce i task e prepara il mob per un nuovo comportamento
---@param mob number Entity handle
---@param netId number Network ID for debug
local function clearMobTasks(mob, netId)
    ClearPedTasks(mob)
    DebugMob(netId, "Cleared all tasks")
end

-- ============================================
-- ATTACK SYSTEM (Async con cooldown)
-- ============================================

--- Inizia l'attacco RPG (non bloccante)
---@param mob number
---@param targetPed number
---@param mobData table
---@param netId number
local function ShootLaser(mob, targetPed, mobData, netId)
    if not DoesEntityExist(mob) or not DoesEntityExist(targetPed) then
        return
    end

    local startCoords = GetPedBoneCoords(mob, 31086, 0.0, 0.0, 0.0) 
    local targetCoords = GetPedBoneCoords(targetPed, 24818, 0.0, 0.0, 0.0)

    ShootSingleBulletBetweenCoords(
        startCoords.x, startCoords.y, startCoords.z, -- Start X, Y, Z
        targetCoords.x, targetCoords.y, targetCoords.z, -- End X, Y, Z
        0,
        true,
        GetHashKey("WEAPON_RAILGUNXM3"),
        mob,
        true,
        false,
        100
    )

    Citizen.CreateThread(function()
        local endTime = GetGameTimer() + 100

        while GetGameTimer() < endTime do
            DrawLine(
                startCoords.x, startCoords.y, startCoords.z,
                targetCoords.x, targetCoords.y, targetCoords.z,
                0, 255, 0, 255
            )

            Citizen.Wait(0)
        end
    end)

    DebugMob(netId, "Shoot Laser! Target: " .. tostring(targetPed))
end

--- Inizia l'attacco melee (non bloccante)
---@param mob number
---@param targetPed number
---@param targetPlayer number
---@param mobConfig table
---@param netId number
---@param mobData table
local function initMeleeAttack(mob, targetPed, targetPlayer, mobConfig, netId, mobData)
    local attack = mobConfig.attackTypes and mobConfig.attackTypes["main"]

    if not attack then
        TaskCombatPed(mob, targetPed, 0, 1)
        mobData.attackCooldown = GetGameTimer() + 2500
        DebugMob(netId, "Basic melee attack (no custom attack config)")
        return
    end

    TaskLookAtEntity(mob, targetPed, 250, 2048, 3)

    local currentTime = GetGameTimer()
    mobData.pendingAttack = {
        targetPed = targetPed,
        targetPlayer = targetPlayer,
        attack = attack,
        executeTime = currentTime + (attack.executeTime or 500),
        executed = false
    }

    local oldState = mobData.state
    mobData.state = MOB_STATE.ATTACKING
    mobData.attackCooldown = currentTime + (attack.cooldown or 750)

    DebugMob(netId, "Initiating melee attack, damage:", attack.damage)
    DebugStateChange(netId, oldState, mobData.state)
end

--- Processa l'attacco melee pendente
---@param mob number
---@param mobData table
---@param netId number
local function processMeleeAttack(mob, mobData, netId)
    if not mobData.pendingAttack then return end

    local currentTime = GetGameTimer()
    local attackData = mobData.pendingAttack

    if not attackData.executed and currentTime >= attackData.executeTime then
        if DoesEntityExist(attackData.targetPed) and not IsPedDeadOrDying(attackData.targetPed, true) then
            if attackData.attack.anim then
                lib.playAnim(mob, attackData.attack.anim.animDict, attackData.attack.anim.animClip,
                        8.0, 8.0, 500, 0, 0.0, false, 0, false)

                local targetServerId = GetPlayerServerId(attackData.targetPlayer)
                local localServerId = GetPlayerServerId(PlayerId())

                if targetServerId == localServerId then
                    ApplyDamageToPed(attackData.targetPed, attackData.attack.damage, false)
                    DebugMob(netId, "Melee hit! Applied", attackData.attack.damage, "damage locally")
                else
                    TriggerServerEvent("nts_mobs:server:playerDamage", targetServerId, netId, attackData.attack.damage)
                    DebugMob(netId, "Melee hit! Sent", attackData.attack.damage, "damage to server for player", targetServerId)
                end
            else
                TaskCombatPed(mob, attackData.targetPed, 0, 16)
                DebugMob(netId, "Melee hit! Basic attack executed")
            end
        else
            DebugMob(netId, "Melee attack cancelled - target dead or doesn't exist")
        end

        attackData.executed = true
        mobData.pendingAttack = nil
        local oldState = mobData.state
        mobData.state = MOB_STATE.COOLDOWN
        DebugStateChange(netId, oldState, mobData.state)
    end
end

-- ============================================
-- BEHAVIOR HANDLERS
-- ============================================

--- Handles mob chasing behavior
---@param mob number
---@param nearPlayer number
---@param nearPlayerDistance number
---@param mobConfig table
---@param netId number
---@param mobData table
local function handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobConfig, netId, mobData)
    local nearPlayerPed = GetPlayerPed(nearPlayer)

    if mobData.state ~= MOB_STATE.CHASING then
        clearMobTasks(mob, netId)
    end

    SetPedMoveRateOverride(mob, mobConfig.speed)

    if not GetIsTaskActive(mob, 233) and not GetIsTaskActive(mob, 35) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end
        TaskGotoEntityAiming(mob, nearPlayerPed, 2.0, 25.0)
        DebugMob(netId, "Chasing player, distance:", string.format("%.2f", nearPlayerDistance))
    end

    local currentTime = GetGameTimer()
    local canAttack = currentTime >= (mobData.attackCooldown or 0)
    print("^2attackCooldwon:^7", mobData.attackCooldown, "currentTime:", currentTime, "canAttack:", tostring(canAttack))
    if nearPlayerDistance <= mobConfig.attackRange and
       not IsPedDeadOrDying(nearPlayerPed, true) and canAttack then
        initMeleeAttack(mob, nearPlayerPed, nearPlayer, mobConfig, netId, mobData)
    elseif nearPlayerDistance <= mobConfig.attackRange and not canAttack then
        local remainingCooldown = (mobData.attackCooldown or 0) - currentTime
        DebugMob(netId, "In attack range but on cooldown:", string.format("%.0fms", remainingCooldown))
    end

    local oldState = mobData.state
    mobData.state = MOB_STATE.CHASING
    DebugStateChange(netId, oldState, mobData.state)
end

--- Handles mob fleeing behavior
---@param mob number
---@param nearPlayer number
---@param mobConfig table
---@param mobData table
---@param netId number
local function handleEscapeFromPlayer(mob, nearPlayer, mobConfig, mobData, netId)
    local nearPlayerPed = GetPlayerPed(nearPlayer)

    if mobData.state ~= MOB_STATE.FLEEING then
        clearMobTasks(mob, netId)
    end

    SetPedMoveRateOverride(mob, mobConfig.speed)

    if not GetIsTaskActive(mob, TASK_SMART_FLEE) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end

        TaskSmartFleePed(mob, nearPlayerPed, 100.0, -1, false, false)
        DebugMob(netId, "Fleeing from player!")
    end

    local oldState = mobData.state
    mobData.state = MOB_STATE.FLEEING
    DebugStateChange(netId, oldState, mobData.state)
end

-- void TaskGoToCoordAnyMeans(int /* Ped */ ped, float x, float y, float z, float fMoveBlendRatio, int /* Vehicle */ vehicle, bool bUseLongRangeVehiclePathing, int drivingFlags, float fMaxRangeToShootTargets);
local function generateCoordsAndGo(mob, zone, mobData, netId)
    local points = GetRandomPoints(zone, Config.Mob.Zone[zone].pos, 1)
    if #points == 0 then
        DebugMob(netId, "No valid points generated for wandering")
        return
    end

    local dest = points[1]
    TaskGoToCoordAnyMeans(mob, dest.x, dest.y, dest.z, (function()
        local speed = mobData.mobConfig.speed or 1.0
        if speed < 0.3 then return 1.0 end
        if speed > 3.0 then return 3.0 end
        return speed
    end)(), 0, false, 786603, 0.0)
    DebugMob(netId, "Wandering to point:", string.format("(%.2f, %.2f, %.2f)", dest.x, dest.y, dest.z))
end

--- Handles mob wandering behavior
---@param mob number
---@param zone number
---@param mobData table
---@param netId number
local function handleWanderingBehavior(mob, zone, mobData, netId)
    if isMobWandering(mob) then
        return
    end

    local oldState = mobData.state
    mobData.state = MOB_STATE.IDLE
    DebugMob(netId, "Wandering task finished, returning to IDLE")
    DebugStateChange(netId, oldState, mobData.state)
end

--- Handles mob idle behavior - attempts to transition to WANDERING
---@param mob number
---@param zone number
---@param mobData table
---@param netId number
local function handleIdleBehavior(mob, zone, mobData, netId)
    if mobData.state ~= MOB_STATE.IDLE and mobData.state ~= MOB_STATE.WANDERING then
        clearMobTasks(mob, netId)
        DebugMob(netId, "Transitioning to IDLE, clearing previous tasks")
    end

    if isMobIdle(mob) then
        -- implement switching from IDLE to WANDERING generating a random point in the zone
        generateCoordsAndGo(mob, zone, mobData, netId)

        local oldState = mobData.state
        mobData.state = MOB_STATE.WANDERING
        DebugStateChange(netId, oldState, mobData.state)
        return
    end

    if mobData.state ~= MOB_STATE.IDLE then
        local oldState = mobData.state
        mobData.state = MOB_STATE.IDLE
        DebugStateChange(netId, oldState, mobData.state)
    end
end

-- ============================================
-- MOB MANAGEMENT
-- ============================================

--- Rimuove un mob dal controllo
---@param netId number
local function removeControlledMob(netId)
    local mobData = CONTROLLED_MOBS[netId]
    if mobData then
        Debug("Removing mob from control: " .. netId)
        CONTROLLED_MOBS[netId] = nil
    end
end

--- Processa la logica di un singolo mob
---@param netId number
---@param mobData table
---@param currentTime number
local function processSingleMob(netId, mobData, currentTime)
    local mob = mobData.mob

    if not DoesEntityExist(mob) or NetworkGetEntityOwner(mob) ~= cache.playerId then
        DebugMob(netId, "Lost ownership or entity doesn't exist, removing from control")
        removeControlledMob(netId)
        return
    end

    processMeleeAttack(mob, mobData, netId)

    if mobData.pendingAttack then
        DebugMob(netId, "Waiting for pending attack to complete...")
        return
    end

    if mobData.state == MOB_STATE.COOLDOWN or mobData.state == MOB_STATE.ATTACKING then
        if currentTime >= (mobData.attackCooldown or 0) then
            local oldState = mobData.state
            mobData.state = MOB_STATE.IDLE
            DebugMob(netId, "Attack cooldown finished")
            DebugStateChange(netId, oldState, mobData.state)
        else
            return
        end
    end

    if currentTime - mobData.lastProcessTime < mobData.tickDelay then
        return
    end
    mobData.lastProcessTime = currentTime

    local nearPlayer, nearPlayerDistance = getClosestPlayerToMob(mob)
    --ensureMovementClipset(mob, mobData.mobConfig, netId)

    if nearPlayerDistance <= mobData.mobConfig.visualRange then
        DebugMob(netId, "Player in visual range:", string.format("%.2f", nearPlayerDistance), "/", mobData.mobConfig.visualRange)

        local nearPlayerPed = GetPlayerPed(nearPlayer)
        if mobData.mobConfig.hasTrollMode and IsEntityPlayingAnim(nearPlayerPed, 'custom@take_l', 'take_l', 3) then
            TaskTurnPedToFaceEntity(mob, nearPlayerPed, 500)
            SetTimeout(500, function() ShootLaser(mob, nearPlayerPed, mobData, netId) end)
            mobData.tickDelay = 2000
        else
            if mobData.mobConfig.behaviour == "aggressive" then
                handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobData.mobConfig, netId, mobData)
            elseif mobData.mobConfig.behaviour == "fugitive" then
                handleEscapeFromPlayer(mob, nearPlayer, mobData.mobConfig, mobData, netId)
            end
            print("This is happening for " .. netId)
            mobData.tickDelay = 150
        end
    else
        if mobData.state == MOB_STATE.WANDERING then
            handleWanderingBehavior(mob, mobData.zone, mobData, netId)
        else
            handleIdleBehavior(mob, mobData.zone, mobData, netId)
        end
        mobData.tickDelay = 1000 
    end
end

-- ============================================
-- CONTROL THREAD
-- ============================================

--- Avvia il thread di controllo centralizzato
local function startControlThread()
    if controlThreadActive then return end

    controlThreadActive = true
    Debug("Mob control thread STARTED - Active mobs: " .. getControlledMobCount())

    CreateThread(function()
        while controlThreadActive do
            local currentTime = GetGameTimer()
            local hasActiveMobs = false

            if Config.Debug then
                closestControlledMobNetId = findClosestControlledMob()
            end

            for netId, mobData in pairs(CONTROLLED_MOBS) do
                hasActiveMobs = true
                processSingleMob(netId, mobData, currentTime)
            end

            if not hasActiveMobs then
                controlThreadActive = false
                closestControlledMobNetId = nil
                Debug("Mob control thread STOPPED - No active mobs")
                break
            end

            Wait(THREAD_TICK_RATE)
        end
    end)
end

--- Aggiunge un mob al sistema di controllo
---@param zone number
---@param netId number
---@param mobType string
local function addControlledMob(zone, netId, mobType)
    if CONTROLLED_MOBS[netId] then
        Debug("Mob already controlled: " .. netId)
        return
    end

    local mob = NetworkGetEntityFromNetworkId(netId)
    local mobConfig = Config.Mob.MobType[mobType]

    if not DoesEntityExist(mob) then 
        Debug("Mob entity does not exist: " .. netId)
        return
    end

    if not mobConfig then
        Debug("Mob config not found for type: " .. tostring(mobType))
        return
    end

    configureMobBehavior(mob)

    CONTROLLED_MOBS[netId] = {
        mob = mob,
        zone = zone,
        mobConfig = mobConfig,
        state = MOB_STATE.IDLE,
        lastProcessTime = 0,
        tickDelay = 500,
        attackCooldown = 0,
        pendingAttack = nil
    }

    Debug("Added mob to control: " .. netId .. " | Total: " .. getControlledMobCount())

    if not controlThreadActive then
        startControlThread()
    end
end

-- ============================================
-- MOBS HANDLERS
-- ============================================

RegisterNetEvent("nts_mobs:client:internal_add_mob", function(zone, netId, mobType)
    --Debug("Received control_mob event - Zone: " .. zone .. " NetId: " .. netId .. " Type: " .. tostring(mobType))
    addControlledMob(zone, netId, mobType)
end)

RegisterNetEvent("nts_mobs:client:internal_remove_mob", function(netId)
    --Debug("Received remove_mob event - NetId: " .. netId)
    removeControlledMob(netId)
end)


-- ============================================
-- EXPORTS (per debug/monitoring)
-- ============================================

exports('getControlledMobsCount', getControlledMobCount)
exports('isControlThreadActive', function() return controlThreadActive end)
exports('getControlledMobs', function() return CONTROLLED_MOBS end)
exports('getClosestControlledMobNetId', function() return closestControlledMobNetId end)

RegisterCommand("mob_controlled_count", function()
    local count = getControlledMobCount()
    print("Currently controlled mobs: " .. count)
    if Config.Debug and closestControlledMobNetId then
        print("Debug focus on mob: " .. closestControlledMobNetId)
    end
end, false)

RegisterCommand("mob_debug_status", function()
    if not Config.Debug then
        print("Debug mode is OFF")
        return
    end

    if not closestControlledMobNetId then
        print("No mob currently being debugged")
        return
    end

    local mobData = CONTROLLED_MOBS[closestControlledMobNetId]
    if mobData then
        print("=== DEBUG MOB #" .. closestControlledMobNetId .. " ===")
        print("State: " .. (MOB_STATE_NAMES[mobData.state] or "UNKNOWN"))
        print("Zone: " .. mobData.zone)
        print("Tick Delay: " .. mobData.tickDelay .. "ms")
        print("Has Pending Attack: " .. tostring(mobData.pendingAttack ~= nil))
        print("Attack Cooldown: " .. (mobData.attackCooldown - GetGameTimer()) .. "ms remaining")
        print("Is Idle (DO_NOTHING): " .. tostring(isMobIdle(mobData.mob)))
        print("Is Wandering: " .. tostring(isMobWandering(mobData.mob)))
        DebugPedTasks(mobData.mob)
    end
end, false)