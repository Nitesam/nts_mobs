local TASK_WANDER = 15
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

-- Stati possibili del mob
local MOB_STATE = {
    IDLE = 1,
    CHASING = 2,
    ATTACKING = 3,
    FLEEING = 4,
    COOLDOWN = 5
}

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
local function ensureMovementClipset(mob, mobConfig)
    local expectedClipset = GetHashKey(mobConfig.movClipset)
    if GetPedMovementClipset(mob) ~= expectedClipset then
        SetPedMovementClipset(mob, mobConfig.movClipset, 1.0)
    end
end

--- Checks if mob is idle and needs a new wandering task
---@param mob number Entity handle
---@return boolean isIdle
local function isMobIdle(mob)
    return (GetIsTaskActive(mob, TASK_AIM_GUN_ON_FOOT) or not GetIsTaskActive(mob, TASK_AIMED_SHOOTING_ON_FOOT)) and not GetIsTaskActive(mob, TASK_WANDER)
end

-- ============================================
-- ATTACK SYSTEM (Async con cooldown)
-- ============================================

--- Inizia l'attacco RPG (non bloccante)
---@param mob number
---@param targetPed number
---@param mobData table
local function initRPGAttack(mob, targetPed, mobData)
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
    mobData.state = MOB_STATE.ATTACKING
    mobData.attackCooldown = currentTime + 3000
end

--- Processa lo sparo RPG pendente
---@param mob number
---@param mobData table
local function processRPGShot(mob, mobData)
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
        end
        rpgData.fired = true
    end
    
    -- Cleanup
    if currentTime >= rpgData.cleanupTime then
        ClearPedTasks(mob)
        RemoveWeaponFromPed(mob, rpgData.weaponHash)
        mobData.pendingRPGShot = nil
        mobData.state = MOB_STATE.IDLE
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
    mobData.state = MOB_STATE.ATTACKING
    mobData.attackCooldown = currentTime + 750
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
            else
                TriggerServerEvent("nts_mobs:server:playerDamage", targetServerId, netId, attackData.attack.damage)
            end
        end

        attackData.executed = true
        mobData.pendingAttack = nil
        mobData.state = MOB_STATE.COOLDOWN
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
    SetPedMoveRateOverride(mob, mobConfig.speed)
    local nearPlayerPed = GetPlayerPed(nearPlayer)

    if not GetIsTaskActive(mob, TASK_AIM_GUN_ON_FOOT) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end
        TaskGotoEntityAiming(mob, nearPlayerPed, 2.0, 25.0)
    end

    local currentTime = GetGameTimer()
    local canAttack = currentTime >= (mobData.attackCooldown or 0)

    if nearPlayerDistance <= mobConfig.attackRange and 
       not IsPedDeadOrDying(nearPlayerPed, true) and canAttack then

        if mobConfig.hasTrollMode and IsEntityPlayingAnim(nearPlayerPed, 'custom@take_l', 'take_l', 3) then
            initRPGAttack(mob, nearPlayerPed, mobData)
        else
            initMeleeAttack(mob, nearPlayerPed, nearPlayer, mobConfig, netId, mobData)
        end
    end
    
    mobData.state = MOB_STATE.CHASING
end

--- Handles mob fleeing behavior
---@param mob number
---@param nearPlayer number
---@param mobConfig table
---@param mobData table
local function handleEscapeFromPlayer(mob, nearPlayer, mobConfig, mobData)
    SetPedMoveRateOverride(mob, mobConfig.speed)
    local nearPlayerPed = GetPlayerPed(nearPlayer)
    if not GetIsTaskActive(mob, TASK_SMART_FLEE) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end
        TaskSmartFleePed(mob, nearPlayerPed, 100.0, -1, false, false)
    end

    mobData.state = MOB_STATE.FLEEING
end

--- Handles mob idle behavior
---@param mob number
---@param zone number
---@param mobData table
local function handleIdleBehavior(mob, zone, mobData)
    local spawnpoint_id = Entity(mob).state.spawnpoint_id
    if isMobIdle(mob) then
        local current_coords = GetEntityCoords(mob)
        TaskWanderInArea(mob, current_coords.x, current_coords.y, current_coords.z, 100.0, 15, 10.0)
        print("Wandering mob: " .. tostring(spawnpoint_id))
    end
    mobData.state = MOB_STATE.IDLE
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
        removeControlledMob(netId)
        return
    end

    processRPGShot(mob, mobData)
    processMeleeAttack(mob, mobData, netId)

    if mobData.pendingAttack or mobData.pendingRPGShot then
        return
    end

    if mobData.state == MOB_STATE.COOLDOWN or mobData.state == MOB_STATE.ATTACKING then
        if currentTime >= (mobData.attackCooldown or 0) then
            mobData.state = MOB_STATE.IDLE
        else
            return
        end
    end

    if currentTime - mobData.lastProcessTime < mobData.tickDelay then
        return
    end
    mobData.lastProcessTime = currentTime

    local nearPlayer, nearPlayerDistance = getClosestPlayerToMob(mob)
    ensureMovementClipset(mob, mobData.mobConfig)

    if nearPlayerDistance <= mobData.mobConfig.visualRange then
        -- Player in range visivo
        if mobData.mobConfig.behaviour == "aggressive" then
            handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobData.mobConfig, netId, mobData)
        elseif mobData.mobConfig.behaviour == "fugitive" then
            handleEscapeFromPlayer(mob, nearPlayer, mobData.mobConfig, mobData)
        end
        mobData.tickDelay = 150
    else

        handleIdleBehavior(mob, mobData.zone, mobData)
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

            for netId, mobData in pairs(controlledMobs) do
                hasActiveMobs = true
                processSingleMob(netId, mobData, currentTime)
            end

            if not hasActiveMobs then
                controlThreadActive = false
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
    print("Received control_mob event - Zone: " .. zone .. " NetId: " .. netId .. " Type: " .. tostring(mobType))
    addControlledMob(zone, netId, mobType)
end)

-- ============================================
-- EXPORTS (per debug/monitoring)
-- ============================================

exports('getControlledMobsCount', getControlledMobCount)
exports('isControlThreadActive', function() return controlThreadActive end)
exports('getControlledMobs', function() return controlledMobs end)

RegisterCommand("mob_controlled_count", function()
    local count = getControlledMobCount()
    print("Currently controlled mobs: " .. count)
end, false)