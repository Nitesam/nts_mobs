local DO_NOTHING = 15
local TASK_WANDER = 222  -- Task ID per TaskWanderInArea
local TASK_AIMED_SHOOTING_ON_FOOT = 35
local TASK_AIM_GUN_ON_FOOT = 233
local TASK_SMART_FLEE = 218
local MOTION_STATE_RUNNING = -530524

-- ============================================
-- SISTEMA CENTRALIZZATO DI CONTROLLO MOB
-- ============================================

local controlledMobs = {}          -- Tabella dei mob controllati
local controlThreadActive = false  -- Flag stato thread
local THREAD_TICK_RATE = 50        -- ms - frequenza base del thread
local closestControlledMobNetId = nil  -- NetId del mob controllato più vicino (per debug)

-- Stati possibili del mob
local MOB_STATE = {
    IDLE = 1,
    WANDERING = 2,
    CHASING = 3,
    ATTACKING = 4,
    FLEEING = 5,
    COOLDOWN = 6
}

-- Nomi stati per debug
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

    for netId, mobData in pairs(controlledMobs) do
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
    for _ in pairs(controlledMobs) do
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
    return GetIsTaskActive(mob, TASK_WANDER)
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
local function initRPGAttack(mob, targetPed, mobData, netId)
    local weaponHash = GetHashKey("WEAPON_RPG")
    GiveWeaponToPed(mob, weaponHash, 1, false, true)
    SetCurrentPedWeapon(mob, weaponHash, true)
    TaskShootAtEntity(mob, targetPed, 1000, 0)

    local currentTime = GetGameTimer()
    mobData.pendingRPGShot = {
        targetPed = targetPed,
        weaponHash = weaponHash,
        fireTime = currentTime + 1000,
        cleanupTime = currentTime + 3000,
        fired = false
    }
    
    local oldState = mobData.state
    mobData.state = MOB_STATE.ATTACKING
    mobData.attackCooldown = currentTime + 3000
    
    DebugMob(netId, "Initiating RPG attack!")
    DebugStateChange(netId, oldState, mobData.state)
end

--- Processa lo sparo RPG pendente
---@param mob number
---@param mobData table
---@param netId number
local function processRPGShot(mob, mobData, netId)
    if not mobData.pendingRPGShot then return end
    
    local currentTime = GetGameTimer()
    local rpgData = mobData.pendingRPGShot
    
    -- Spara il colpo
    if not rpgData.fired and currentTime >= rpgData.fireTime then
        if DoesEntityExist(rpgData.targetPed) then
            local mobCoords = GetEntityCoords(mob)
            local targetCoords = GetEntityCoords(rpgData.targetPed)

            ShootSingleBulletBetweenCoords(
                mobCoords.x, mobCoords.y, mobCoords.z + 1.0,
                targetCoords.x, targetCoords.y, targetCoords.z + 1.0,
                5, true, rpgData.weaponHash, mob, true, false, 1000.0
            )
            DebugMob(netId, "RPG fired!")
        else
            DebugMob(netId, "RPG target no longer exists, cancelling shot")
        end
        rpgData.fired = true
    end
    
    -- Cleanup
    if currentTime >= rpgData.cleanupTime then
        ClearPedTasks(mob)
        RemoveWeaponFromPed(mob, rpgData.weaponHash)
        mobData.pendingRPGShot = nil
        local oldState = mobData.state
        mobData.state = MOB_STATE.IDLE
        DebugMob(netId, "RPG attack cleanup complete")
        DebugStateChange(netId, oldState, mobData.state)
    end
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
        TaskMeleeAttackPed(mob, targetPed, 0, 1)
        mobData.attackCooldown = GetGameTimer() + 1000
        DebugMob(netId, "Basic melee attack (no custom attack config)")
        return
    end

    TaskLookAtEntity(mob, targetPed, 250, 2048, 3)

    local currentTime = GetGameTimer()
    mobData.pendingAttack = {
        targetPed = targetPed,
        targetPlayer = targetPlayer,
        attack = attack,
        executeTime = currentTime + 250,
        executed = false
    }
    
    local oldState = mobData.state
    mobData.state = MOB_STATE.ATTACKING
    mobData.attackCooldown = currentTime + 750
    
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
    
    -- Pulisci i task solo quando si entra nello stato CHASING per la prima volta
    if mobData.state ~= MOB_STATE.CHASING then
        clearMobTasks(mob, netId)
    end
    
    SetPedMoveRateOverride(mob, mobConfig.speed)

    -- Riassegna il task solo se non è già attivo
    if not GetIsTaskActive(mob, TASK_AIM_GUN_ON_FOOT) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end
        TaskGotoEntityAiming(mob, nearPlayerPed, 2.0, 25.0)
        DebugMob(netId, "Chasing player, distance:", string.format("%.2f", nearPlayerDistance))
    end

    local currentTime = GetGameTimer()
    local canAttack = currentTime >= (mobData.attackCooldown or 0)

    if nearPlayerDistance <= mobConfig.attackRange and 
       not IsPedDeadOrDying(nearPlayerPed, true) and canAttack then

        if mobConfig.hasTrollMode and IsEntityPlayingAnim(nearPlayerPed, 'custom@take_l', 'take_l', 3) then
            DebugMob(netId, "Troll mode activated! Switching to RPG")
            initRPGAttack(mob, nearPlayerPed, mobData, netId)
        else
            initMeleeAttack(mob, nearPlayerPed, nearPlayer, mobConfig, netId, mobData)
        end
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
    
    -- Pulisci i task solo quando si entra nello stato FLEEING per la prima volta
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

--- Handles mob wandering behavior
---@param mob number
---@param zone number
---@param mobData table
---@param netId number
local function handleWanderingBehavior(mob, zone, mobData, netId)
    -- Verifica se il mob sta ancora wanderando
    if isMobWandering(mob) then
        -- Tutto ok, continua a wanderare
        return
    end
    
    -- Il mob ha smesso di wanderare, torna in IDLE
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
    -- Se stiamo arrivando da un altro stato (non IDLE e non WANDERING), pulisci i task
    if mobData.state ~= MOB_STATE.IDLE and mobData.state ~= MOB_STATE.WANDERING then
        clearMobTasks(mob, netId)
        DebugMob(netId, "Transitioning to IDLE, clearing previous tasks")
    end
    
    -- Se il mob è veramente idle (non sta facendo nulla), assegna wandering
    if isMobIdle(mob) then
        local current_coords = GetEntityCoords(mob)
        TaskWanderStandard(mob, 10.0, 10)

        local spawnpoint_id = Entity(mob).state.spawnpoint_id
        DebugMob(netId, "Started wandering from IDLE, spawnpoint:", spawnpoint_id)

        -- Transizione a WANDERING
        local oldState = mobData.state
        mobData.state = MOB_STATE.WANDERING
        DebugStateChange(netId, oldState, mobData.state)
        return
    end
    
    -- Altrimenti, imposta lo stato come IDLE e attendi
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
    local mobData = controlledMobs[netId]
    if mobData then
        Debug("Removing mob from control: " .. netId)
        TriggerServerEvent("nts_mobs:lostOwnership", mobData.zone, netId)
        controlledMobs[netId] = nil
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

    processRPGShot(mob, mobData, netId)
    processMeleeAttack(mob, mobData, netId)

    if mobData.pendingAttack or mobData.pendingRPGShot then
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
        
        if mobData.mobConfig.behaviour == "aggressive" then
            handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobData.mobConfig, netId, mobData)
        elseif mobData.mobConfig.behaviour == "fugitive" then
            handleEscapeFromPlayer(mob, nearPlayer, mobData.mobConfig, mobData, netId)
        end
        mobData.tickDelay = 150
    else
        -- Nessun player in range - gestisci stato IDLE/WANDERING
        if mobData.state == MOB_STATE.WANDERING then
            -- Già in wandering, verifica se sta ancora wanderando
            handleWanderingBehavior(mob, mobData.zone, mobData, netId)
        else
            -- In IDLE o altro stato, tenta di iniziare il wandering
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

            -- Aggiorna il mob più vicino per il debug (solo se debug attivo per evitare overhead)
            if Config.Debug then
                closestControlledMobNetId = findClosestControlledMob()
            end

            for netId, mobData in pairs(controlledMobs) do
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
    if controlledMobs[netId] then
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

    controlledMobs[netId] = {
        mob = mob,
        zone = zone,
        mobConfig = mobConfig,
        state = MOB_STATE.IDLE,
        lastProcessTime = 0,
        tickDelay = 500,
        attackCooldown = 0,
        pendingAttack = nil,
        pendingRPGShot = nil
    }

    Debug("Added mob to control: " .. netId .. " | Total: " .. getControlledMobCount())

    if not controlThreadActive then
        startControlThread()
    end
end

-- ============================================
-- EVENT HANDLERS
-- ============================================

RegisterNetEvent("nts_mobs:client:control_mob", function(zone, netId, mobType)
    Debug("Received control_mob event - Zone: " .. zone .. " NetId: " .. netId .. " Type: " .. tostring(mobType))
    addControlledMob(zone, netId, mobType)
end)

-- ============================================
-- EXPORTS (per debug/monitoring)
-- ============================================

exports('getControlledMobsCount', getControlledMobCount)
exports('isControlThreadActive', function() return controlThreadActive end)
exports('getControlledMobs', function() return controlledMobs end)
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

    local mobData = controlledMobs[closestControlledMobNetId]
    if mobData then
        print("=== DEBUG MOB #" .. closestControlledMobNetId .. " ===")
        print("State: " .. (MOB_STATE_NAMES[mobData.state] or "UNKNOWN"))
        print("Zone: " .. mobData.zone)
        print("Tick Delay: " .. mobData.tickDelay .. "ms")
        print("Has Pending Attack: " .. tostring(mobData.pendingAttack ~= nil))
        print("Has Pending RPG: " .. tostring(mobData.pendingRPGShot ~= nil))
        print("Attack Cooldown: " .. (mobData.attackCooldown - GetGameTimer()) .. "ms remaining")
        print("Is Idle (DO_NOTHING): " .. tostring(isMobIdle(mobData.mob)))
        print("Is Wandering: " .. tostring(isMobWandering(mobData.mob)))
        DebugPedTasks(mobData.mob)
    end
end, false)