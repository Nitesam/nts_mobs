-- IL SEGUENTE FILE E' STATO RIORGANIZZATO PER SEGUIRE GLI STANDARD SRP, NON SAPENDO SE CONTINUERO' SEMPRE IO
-- (NITESAM) LO SVILUPPO DEL BEHAVIOUR (LA PARTE LOGICA DELLO SCRIPT), OGNI FUNZIONE HA UN COMMENTO CHE SPIEGA IL SUO SCOPO,
-- I COMMENTI SONO GENERATI DA OPUS 4.5, SONO LAZY E MI SECCAVO A FARLI MANUALMENTE :)

-- ENUMS LOCALI PER ACCESSO PIU' VELOCE, HO EVITATO DI CHIAMARE LA GLOBAL ENUM O DICHIARARE VAR LOCALI PER TASK TIPO LA 233.
local DO_NOTHING = 15
local TASK_WANDER = 222
local TASK_GO_TO_COORD_ANY_MEANS = 224
local TASK_SMART_FLEE = 218
local MOTION_STATE_RUNNING = -530524

-- ============================================
-- SISTEMA CENTRALIZZATO DI CONTROLLO MOB
-- ============================================

CONTROLLED_MOBS = {}                       -- Tabella dei mob controllati

local controlThreadActive = false          -- Flag stato thread
local THREAD_TICK_RATE = 50                -- ms - frequenza base del thread
local closestControlledMobNetId = nil      -- NetId del mob controllato più vicino (per debug)

local STUCK_CHECK_INTERVAL = 250           -- ms - intervallo tra i controlli di movimento
local STUCK_DISTANCE_THRESHOLD = 0.02      -- unità - distanza minima considerata come movimento
local REQUIRED_STUCK_CHECKS = 1            -- numero di controlli consecutivi prima di considerare il mob bloccato
local WANDER_TASK_GRACE_MS <const> = 2000  -- ms - evita clear immediato dopo assegnazione wander
local SPAWN_WANDER_DELAY_MS <const> = 100  -- ms - non assegnare wander subito allo spawn

local MOB_STATE <const> = {
    IDLE = 1,
    WANDERING = 2,
    CHASING = 3,
    ATTACKING = 4,
    FLEEING = 5,
    COOLDOWN = 6,
    RETURNING = 7
}

MOB_STATE_NAMES = {
    [1] = "IDLE",
    [2] = "WANDERING",
    [3] = "CHASING",
    [4] = "ATTACKING",
    [5] = "FLEEING",
    [6] = "COOLDOWN",
    [7] = "RETURNING"
}

local MOB_STATE_NAMES = MOB_STATE_NAMES

-- Stati che richiedono persistenza via statebag
local CRITICAL_STATES <const> = {
    [MOB_STATE.CHASING] = true,
    [MOB_STATE.ATTACKING] = true,
    [MOB_STATE.COOLDOWN] = true
}

-- ============================================
-- DEBUG FUNCTIONS
-- ============================================

--- Debug solo per il mob più vicino
---@param netId number Network ID del mob
---@param ... any Messaggi da stampare

local debugmobenabled = false
local function DebugMob(netId, ...)
    if not Config.Debug then return end
    if netId ~= closestControlledMobNetId then return end
    if not debugmobenabled then return end

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

local function SwitchToMobState(mobData, newState, netId)
    if mobData.state == newState then return false end
    local oldState = mobData.state
    mobData.state = newState
    DebugStateChange(netId, oldState, newState)
    return true
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
-- STATEBAG FUNCTIONS (per ownership handoff)
-- ============================================

--- Salva lo stato critico del mob nello statebag (solo quando necessario)
--- @param mob number Entity handle
--- @param mobData table Dati del mob
--- @param netId number Network ID
local function saveCriticalState(mob, mobData, netId)
    if not CRITICAL_STATES[mobData.state] then return end
    if not mobData.currentTarget then return end

    local targetServerId = GetPlayerServerId(mobData.currentTarget)
    if targetServerId <= 0 then return end

    local entityState = Entity(mob).state
    if entityState.combatTarget ~= targetServerId then
        entityState:set('combatTarget', targetServerId, true)
        entityState:set('combatState', mobData.state, true)
        DebugMob(netId, "Saved critical state to statebag - Target:", targetServerId, "State:", MOB_STATE_NAMES[mobData.state])
    end
end

--- Pulisce lo stato critico dallo statebag (quando non più in combattimento)
--- @param mob number Entity handle
--- @param netId number Network ID
local function clearCriticalState(mob, netId)
    local entityState = Entity(mob).state
    if entityState.combatTarget then
        entityState:set('combatTarget', nil, true)
        entityState:set('combatState', nil, true)
        DebugMob(netId, "Cleared critical state from statebag")
    end
end

--- Legge lo stato critico dallo statebag (quando si acquisisce ownership)
--- @param mob number Entity handle
--- @return number|nil targetServerId, number|nil state
local function readCriticalState(mob)
    local entityState = Entity(mob).state
    return entityState.combatTarget, entityState.combatState
end

--- Converte server ID in player ID locale
--- @param serverId number Server ID del player
--- @return number|nil playerId locale o nil se non trovato
local function getPlayerFromServerId(serverId)
    for _, playerId in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(playerId) == serverId then
            return playerId
        end
    end
    return nil
end

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function clearMobTasks(mob, netId)
    local mobData = CONTROLLED_MOBS[netId]
    if mobData and mobData.state == MOB_STATE.WANDERING then
        local now = GetGameTimer()
        local issuedAt = mobData.lastWanderIssuedAt or 0
        if mobData.goingToCoords and (now - issuedAt) < WANDER_TASK_GRACE_MS then
            DebugMob(netId, "Skipped clearing tasks: wander grace window")
            return
        end
    end

    -- if GetIsTaskActive(mob, 222) then Entity(mob).state:set('illegal:clearingWhileWandering', true, true) end
    mobData.usedClearPedTasks = true
    SetTimeout(250, function() mobData.usedClearPedTasks = false end)

    ClearPedTasks(mob)
    DebugMob(netId, "Cleared all tasks")
end

local function getControlledMobCount()
    local count = 0
    for _ in pairs(CONTROLLED_MOBS) do
        count = count + 1
    end
    return count
end

-- void TaskGoToCoordAnyMeans(int /* Ped */ ped, float x, float y, float z, float fMoveBlendRatio, int /* Vehicle */ vehicle, bool bUseLongRangeVehiclePathing, int drivingFlags, float fMaxRangeToShootTargets);
local MAX_SPAWN_RETRIES <const> = 20
local function generateCoordsAndGo(mob, zone, mobData, netId, try)
    local try = try or 0
    local points = GetRandomPoints(zone, Config.Mob.Zone[zone].pos, 1)
    mobData.goingToCoords = nil
    mobData.pendingWanderIssuedAt = nil
    mobData.pendingWander = nil

    if #points == 0 then
        Wait(0)
        local is_max_reached = try > MAX_SPAWN_RETRIES
        --print("^1[MOB DEBUG #" .. netId .. "]^2 Max wandering point generation retries reached, giving up.^7")
        return is_max_reached and nil or generateCoordsAndGo(mob, zone, mobData, netId, try + 1)
    end

    local dest = points[1]
    local speed = (function()
        local speed = mobData.mobConfig.speed or 1.0
        if speed < 0.3 then return 0.3 end
        if speed > 3.0 then return 3.0 end
        return speed
    end)()

    TaskGoToCoordAnyMeans(mob, dest.x, dest.y, dest.z, speed, 0, false, 786603, 0.0)

    --TriggerServerEvent('nts_mobs:server:mob_go_to_coords', netId, dest, speed)

    mobData.goingToCoords = dest

    local now = GetGameTimer()
    mobData.lastWanderIssuedAt = now
    mobData.pendingWanderIssuedAt = now
    mobData.pendingWander = true
end

--- Configures mob behavior attributes (audio, combat, flee)
---@param mob number Entity handle
local function configureMobBehavior(mob)
    SetEntityAsMissionEntity(mob, true, true)

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
local function ensureMovementClipset(mob, mobConfig, netId) -- non usata per ora, idk al momento se serve in base alle richieste di black, prima lo usavo
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

--- Verifica se il mob è bloccato (non si muove da troppo tempo)
---@param mob number Entity handle
---@param mobData table Dati del mob
---@param netId number Network ID
---@return boolean isStuck
local function isMobStuck(mob, mobData, netId, mobCoords)
    local currentPos = mobCoords or GetEntityCoords(mob)
    local currentTime = GetGameTimer()

    if not mobData.lastMovementCoords then
        mobData.lastMovementCoords = currentPos
        mobData.lastMovementCheckTime = currentTime
        mobData.stuckAttempts = 0
        return false
    end

    if currentTime - (mobData.lastMovementCheckTime or 0) < STUCK_CHECK_INTERVAL then
        return false
    end

    local distance = #(currentPos - mobData.lastMovementCoords)
    mobData.lastMovementCoords = currentPos
    mobData.lastMovementCheckTime = currentTime

    local shouldCheckStuck = (mobData.state == MOB_STATE.WANDERING) or (mobData.state == MOB_STATE.RETURNING)

    if shouldCheckStuck and distance <= STUCK_DISTANCE_THRESHOLD then
        mobData.stuckAttempts = (mobData.stuckAttempts or 0) + 1
        DebugMob(netId, "Mob appears stuck (check #" .. mobData.stuckAttempts .. ")", string.format("%.2f", distance), "units in", STUCK_CHECK_INTERVAL .. "ms")
        if mobData.stuckAttempts >= REQUIRED_STUCK_CHECKS then
            mobData.stuckAttempts = 0
            return true
        end
        return false
    end

    mobData.stuckAttempts = 0
    return false
end

local function recoverStuckMob(mob, zone, mobData, netId)
    --clearMobTasks(mob, netId)
    mobData.lastMovementCoords = nil
    mobData.lastMovementCheckTime = 0
    mobData.stuckAttempts = 0
    mobData.stuckRecoveryCount = (mobData.stuckRecoveryCount or 0) + 1

    --generateCoordsAndGo(mob, zone, mobData, netId)

    if mobData.stuckRecoveryCount % 3 == 0 then
        mobData.stuckRecoveryCount = 0
        TaskWanderInArea(mob, mobData.currentCoords.x, mobData.currentCoords.y, mobData.currentCoords.z, 10.0, 8, 0)
        DebugMob(netId, "Fallback wander task issued to recover stuck mob")
    else
        generateCoordsAndGo(mob, zone, mobData, netId)
    end

    SwitchToMobState(mobData, MOB_STATE.WANDERING, netId)
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

        SwitchToMobState(mobData, MOB_STATE.ATTACKING, netId)

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

    SwitchToMobState(mobData, MOB_STATE.ATTACKING, netId)
    mobData.attackCooldown = currentTime + (attack.cooldown or 750)

    DebugMob(netId, "Initiating melee attack, damage:", attack.damage)
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
        SwitchToMobState(mobData, MOB_STATE.COOLDOWN, netId)
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

    if IsPedDeadOrDying(nearPlayerPed, true) then
        DebugMob(netId, "Target is dead, looking for new target")
        mobData.currentTarget = nil
        clearCriticalState(mob, netId)
        SwitchToMobState(mobData, MOB_STATE.IDLE, netId)
        clearMobTasks(mob, netId)
        return
    end

    mobData.currentTarget = nearPlayer

    if mobData.state ~= MOB_STATE.CHASING and
       mobData.state ~= MOB_STATE.ATTACKING and
       mobData.state ~= MOB_STATE.COOLDOWN then
        clearMobTasks(mob, netId)
    end

    SetPedMoveRateOverride(mob, mobConfig.speed)

    local currentTime = GetGameTimer()
    local canAttack = currentTime >= (mobData.attackCooldown or 0)

    if nearPlayerDistance <= mobConfig.attackRange then
        if canAttack then
            initMeleeAttack(mob, nearPlayerPed, nearPlayer, mobConfig, netId, mobData)
            return
        else
            local remainingCooldown = (mobData.attackCooldown or 0) - currentTime
            DebugMob(netId, "In attack range but on cooldown:", string.format("%.0fms", remainingCooldown))
            TaskTurnPedToFaceEntity(mob, nearPlayerPed, 500)
        end
    else
        local isInCombat = GetIsTaskActive(mob, 233) or GetIsTaskActive(mob, 35) or GetIsTaskActive(mob, 287)
        if not isInCombat then
            if mobConfig.speed > 1.0 then
                ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
            end
            TaskGotoEntityAiming(mob, nearPlayerPed, 2.0, 25.0)
            DebugMob(netId, "Chasing player, distance:", string.format("%.2f", nearPlayerDistance))
        end
    end

    SwitchToMobState(mobData, MOB_STATE.CHASING, netId)

    if not mobData.lastStatebagUpdate or (GetGameTimer() - mobData.lastStatebagUpdate) > 2000 then
        saveCriticalState(mob, mobData, netId)
        mobData.lastStatebagUpdate = GetGameTimer()
    end
end

--- Handles mob fleeing behavior
---@param mob number
---@param nearPlayer number
---@param mobConfig table
---@param mobData table
---@param netId number
local function handleEscapeFromPlayer(mob, nearPlayer, mobConfig, mobData, netId)
    local nearPlayerPed = GetPlayerPed(nearPlayer)

    if IsPedDeadOrDying(nearPlayerPed, true) then
        DebugMob(netId, "Player is dead, no need to flee")
        mobData.currentTarget = nil
        SwitchToMobState(mobData, MOB_STATE.IDLE, netId)
        clearMobTasks(mob, netId)
        return
    end

    if mobData.state ~= MOB_STATE.FLEEING then
        clearMobTasks(mob, netId)
    end

    SetPedMoveRateOverride(mob, mobConfig.speed)

    if not GetIsTaskActive(mob, TASK_SMART_FLEE) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end
        local distance_to_flee = mobConfig.escapeDistanceMax?.min and mobConfig.escapeDistanceMax?.max and
            math.random(mobConfig.escapeDistanceMax.min, mobConfig.escapeDistanceMax.max) or 100.0

        TaskSmartFleePed(mob, nearPlayerPed, distance_to_flee + 0.0, 3000, false, false)
        DebugMob(netId, "Fleeing from player! (15s duration)")
    end

    SwitchToMobState(mobData, MOB_STATE.FLEEING, netId)
end

--- Handles mob wandering behavior
---@param mob number
---@param zone number
---@param mobData table
---@param netId number
local function handleWanderingBehavior(mob, zone, mobData, netId)
    if isMobStuck(mob, mobData, netId, mobData.currentCoords) then
        DebugMob(netId, "Mob is stuck during wandering, trying to recover")
        recoverStuckMob(mob, zone, mobData, netId)
        return
    end
    
    if isMobWandering(mob) then
        SwitchToMobState(mobData, MOB_STATE.WANDERING, netId)
        return
    end

    if not isMobIdle(mob) then
        SwitchToMobState(mobData, MOB_STATE.WANDERING, netId)
        return
    end

    DebugMob(netId, "Wandering task finished, returning to IDLE")
    SwitchToMobState(mobData, MOB_STATE.IDLE, netId)
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

    local now = GetGameTimer()

    if (now - (mobData.spawnedAt or 0)) < SPAWN_WANDER_DELAY_MS then
        return
    end

    if mobData.pendingWander then
        if GetIsTaskActive(mob, TASK_GO_TO_COORD_ANY_MEANS) or GetIsTaskActive(mob, TASK_WANDER) then
            mobData.pendingWander = nil
            mobData.pendingWanderIssuedAt = nil
            SwitchToMobState(mobData, MOB_STATE.WANDERING, netId)
            return
        end

        if (now - (mobData.pendingWanderIssuedAt or 0)) > WANDER_TASK_GRACE_MS then
            DebugMob(netId, "Wander task not started, retrying")
            mobData.pendingWander = nil
            mobData.pendingWanderIssuedAt = nil
            mobData.goingToCoords = nil
            generateCoordsAndGo(mob, zone, mobData, netId)
            return
        end

        return -- still within grace window waiting for task to start
    end

    if isMobIdle(mob) then
        generateCoordsAndGo(mob, zone, mobData, netId)
        return
    end

    SwitchToMobState(mobData, MOB_STATE.IDLE, netId)
end

local function returnToZone(mob, zone, mobData, netId)
    if mobData.state ~= MOB_STATE.RETURNING then
        clearMobTasks(mob, netId)
    end
    
    mobData.lastMovementCoords = nil
    mobData.lastMovementCheckTime = 0
    mobData.stuckAttempts = 0
    
    generateCoordsAndGo(mob, zone, mobData, netId)
    DebugMob(netId, "Returning to zone:", zone)
    SwitchToMobState(mobData, MOB_STATE.RETURNING, netId)
    Debug("^1[MOB DEBUG #" .. netId .. "]^2 Returning to zone " .. zone .. "^7")
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

    if IsPedDeadOrDying(mob, true) then
        return
    end

    processMeleeAttack(mob, mobData, netId)

    if mobData.pendingAttack then
        DebugMob(netId, "Waiting for pending attack to complete...")
        return
    end

    if mobData.state == MOB_STATE.COOLDOWN or mobData.state == MOB_STATE.ATTACKING then
        if currentTime >= (mobData.attackCooldown or 0) then
            DebugMob(netId, "Attack cooldown finished, returning to chase")
            SwitchToMobState(mobData, MOB_STATE.CHASING, netId)
        else
            return
        end
    end

    if currentTime - mobData.lastProcessTime < mobData.tickDelay then
        return
    end
    mobData.lastProcessTime = currentTime
    mobData.currentCoords = GetEntityCoords(mob)

    local nearPlayer, nearPlayerDistance = getClosestPlayerToMob(mob, mobData.currentCoords)
    local nearPlayerPed = GetPlayerPed(nearPlayer)

    if mobData.mobConfig.hasTrollMode and nearPlayerDistance <= (mobData.mobConfig.visualRange * 2) and IsEntityPlayingAnim(nearPlayerPed, 'custom@take_l', 'take_l', 3) then
        TaskTurnPedToFaceEntity(mob, nearPlayerPed, 500)
        SetTimeout(500, function() ShootLaser(mob, nearPlayerPed, mobData, netId) end)
        mobData.tickDelay = 2000
        return
    end

    if mobData.state == MOB_STATE.RETURNING and nearPlayerDistance <= mobData.mobConfig.visualRange then
        DebugMob(netId, "Player detected while returning, distance:", string.format("%.2f", nearPlayerDistance))
        
        if mobData.mobConfig.behaviour == "aggressive" then
            handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobData.mobConfig, netId, mobData)
            mobData.tickDelay = 150
            return
        elseif mobData.mobConfig.behaviour == "fugitive" then
            handleEscapeFromPlayer(mob, nearPlayer, mobData.mobConfig, mobData, netId)
            mobData.tickDelay = 150
            return
        end
    end

    local isMobOutOfZone = not zoneMob[mobData.zone].poly:contains(mobData.currentCoords)
    
    if (mobData.state == MOB_STATE.WANDERING or mobData.state == MOB_STATE.IDLE) and isMobOutOfZone then
        returnToZone(mob, mobData.zone, mobData, netId)
        mobData.tickDelay = 500
        return
    elseif isMobOutOfZone and mobData.state == MOB_STATE.RETURNING then
        local isMoving = GetIsTaskActive(mob, TASK_GO_TO_COORD_ANY_MEANS) or GetIsTaskActive(mob, TASK_WANDER)
        
        if not isMoving then
            DebugMob(netId, "Return task not active, reissuing immediately")
            generateCoordsAndGo(mob, mobData.zone, mobData, netId)
            mobData.tickDelay = 100
            return
        end
        
        if isMobStuck(mob, mobData, netId, mobData.currentCoords) then
            DebugMob(netId, "Returning mob is stuck, trying to recover")
            recoverStuckMob(mob, mobData.zone, mobData, netId)
            mobData.tickDelay = 100
            return
        end

        mobData.tickDelay = 250
        return 
    elseif not isMobOutOfZone and mobData.state == MOB_STATE.RETURNING then
        DebugMob(netId, "Mob finished returning, resuming idle/wander")
        clearMobTasks(mob, netId)
        SwitchToMobState(mobData, MOB_STATE.IDLE, netId)
        mobData.tickDelay = 100
    end

    if nearPlayerDistance <= mobData.mobConfig.visualRange then
        DebugMob(netId, "Player in visual range:", string.format("%.2f", nearPlayerDistance), "/", mobData.mobConfig.visualRange)

        if mobData.mobConfig.behaviour == "aggressive" then
            handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobData.mobConfig, netId, mobData)
        else
            handleEscapeFromPlayer(mob, nearPlayer, mobData.mobConfig, mobData, netId)
        end
        mobData.tickDelay = 150
    else
        if mobData.state == MOB_STATE.FLEEING and GetIsTaskActive(mob, TASK_SMART_FLEE) then
            --[[if isMobStuck(mob, mobData, netId, mobData.currentCoords) then
                DebugMob(netId, "Fleeing mob is stuck, stopping flee and returning to idle")
                clearMobTasks(mob, netId)
                SwitchToMobState(mobData, MOB_STATE.IDLE, netId)
            else]]
                if not mobData.lastFleeDebugTime or (currentTime - mobData.lastFleeDebugTime) > 5000 then
                    mobData.lastFleeDebugTime = currentTime
                end
                mobData.tickDelay = 100
                return
            --end
        end

        if mobData.state == MOB_STATE.WANDERING then
            handleWanderingBehavior(mob, mobData.zone, mobData, netId)
        else
            handleIdleBehavior(mob, mobData.zone, mobData, netId)
        end
        mobData.tickDelay = 100
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

    while not HasCollisionLoadedAroundEntity(mob) do
        if not DoesEntityExist(mob) then return end
        Wait(50)
    end

    FreezeEntityPosition(mob, false)
    configureMobBehavior(mob)

    local savedTargetServerId, savedState = readCriticalState(mob)
    local restoredTarget = nil
    local initialState = isMobWandering(mob) and MOB_STATE.WANDERING or MOB_STATE.IDLE

    if savedTargetServerId and savedState and CRITICAL_STATES[savedState] then
        restoredTarget = getPlayerFromServerId(savedTargetServerId)
        if restoredTarget then
            local restoredPed = GetPlayerPed(restoredTarget)
            if DoesEntityExist(restoredPed) and not IsPedDeadOrDying(restoredPed, true) then
                initialState = savedState
                --Debug("Restored critical state from statebag - Target: " .. savedTargetServerId .. " State: " .. MOB_STATE_NAMES[savedState])
            else
                clearCriticalState(mob, netId)
            end
        else
            clearCriticalState(mob, netId)
        end
    end

    CONTROLLED_MOBS[netId] = {
        mob = mob,
        zone = zone,
        mobConfig = mobConfig,
        state = initialState,
        currentTarget = restoredTarget,
        lastProcessTime = 0,
        tickDelay = 500,
        attackCooldown = 0,
        pendingAttack = nil,
        lastStatebagUpdate = 0,
        lastMovementCoords = nil,
        lastMovementCheckTime = 0,
        stuckAttempts = 0,
        stuckRecoveryCount = 0,
        lastFleeDebugTime = 0,
        spawnedAt = GetGameTimer()
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
    if Config.Debug then exports.nts_mobs:ESP_AddEntity(NetworkGetEntityFromNetworkId(netId), mobType, "enemy") end
    addControlledMob(zone, netId, mobType)
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