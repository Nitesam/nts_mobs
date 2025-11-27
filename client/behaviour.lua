local TASK_WANDER = 15
local TASK_AIMED_SHOOTING_ON_FOOT = 35
local TASK_AIM_GUN_ON_FOOT = 233
local MOTION_STATE_RUNNING = -530524

local function ShootWithRPG(mob, targetPed)
    local weaponHash = GetHashKey("WEAPON_RPG")
    GiveWeaponToPed(mob, weaponHash, 1, false, true)
    SetCurrentPedWeapon(mob, weaponHash, true)
    TaskShootAtEntity(mob, targetPed, 1000, 0)

    Wait(1000)

    local mobCoords = GetEntityCoords(mob)
    local targetCoords = GetEntityCoords(targetPed)

    ShootSingleBulletBetweenCoords(
        mobCoords.x, mobCoords.y, mobCoords.z + 1.0,
        targetCoords.x, targetCoords.y, targetCoords.z + 1.0,
        5,      -- damage
        true,   -- pureAccuracy
        weaponHash,
        mob,    -- ownerPed
        true,   -- isAudible
        false,  -- isInvisible
        1000.0  -- speed
    )

    Citizen.SetTimeout(2000, function()
        ClearPedTasks(mob)
        RemoveWeaponFromPed(mob, weaponHash)
    end)
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
        --Debug("Mov clipset changed to " .. mobConfig.movClipset .. " for " .. netId)
    end
end

--- Performs attack on target player
---@param mob number Entity handle
---@param targetPed number Target player ped
---@param targetPlayer number Target player ID
---@param mobConfig table Mob type configuration
---@param netId number Network ID
local function performAttack(mob, targetPed, targetPlayer, mobConfig, netId)
    local attack = mobConfig.attackTypes["main"]

    TaskLookAtEntity(mob, targetPed, 250, 2048, 3)
    Wait(250)
    lib.playAnim(mob, attack.anim.animDict, attack.anim.animClip, 8.0, 8.0, 500, 0, 0.0, false, 0, false)

    local targetServerId = GetPlayerServerId(targetPlayer)
    local localServerId = GetPlayerServerId(PlayerId())

    if targetServerId == localServerId then
        ApplyDamageToPed(targetPed, attack.damage, false)
    else
        TriggerServerEvent("nts_mobs:server:playerDamage", targetServerId, netId, attack.damage)
    end
end

--- Handles mob chasing behavior when player is in visual range
---@param mob number Entity handle
---@param nearPlayer number Nearest player ID
---@param nearPlayerDistance number Distance to nearest player
---@param mobConfig table Mob type configuration
---@param netId number Network ID
---@return boolean attacked Whether an attack was performed
local function handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobConfig, netId)
    SetPedMoveRateOverride(mob, mobConfig.speed)
    local nearPlayerPed = GetPlayerPed(nearPlayer)

    if not GetIsTaskActive(mob, TASK_AIM_GUN_ON_FOOT) then
        if mobConfig.speed > 1.0 then
            ForcePedMotionState(mob, MOTION_STATE_RUNNING, false, 0, 0)
        end
        TaskGotoEntityAiming(mob, nearPlayerPed, 2.0, 25.0)
    end

    if nearPlayerDistance <= mobConfig.attackRange and not IsPedDeadOrDying(nearPlayerPed, true) then
        if IsEntityPlayingAnim(nearPlayerPed, 'custom@take_l', 'take_l', 3) then -- troll feature
            ShootWithRPG(mob, nearPlayerPed)
        else
            performAttack(mob, nearPlayerPed, nearPlayer, mobConfig, netId)
        end

        return true
    end

    return false
end

--- Checks if mob is idle and needs a new wandering task
---@param mob number Entity handle
---@return boolean isIdle
local function isMobIdle(mob)
    local isWandering = GetIsTaskActive(mob, TASK_WANDER) and not GetIsTaskActive(mob, TASK_AIMED_SHOOTING_ON_FOOT)
    local isAiming = GetIsTaskActive(mob, TASK_AIM_GUN_ON_FOOT)
    return isWandering or isAiming
end

--- Makes mob wander to a random point in the zone
---@param mob number Entity handle
---@param zone number Zone index
---@param netId number Network ID for debug
local function makeWander(mob, zone, netId)
    local points = GetRandomPoints(zone, Config.Mob.Zone[zone].pos, 1)

    if points and points[1] then
        local coords = points[1]
        ClearPedTasks(mob)
        TaskGoToCoordAnyMeans(mob, coords.x, coords.y, coords.z, 1.0, 0, 0, 786603, 0xbf800000)
        Debug(netId .. " wasn't doing anything, so i made him walking")
    end
end

--- Handles mob idle behavior when no player is in visual range
---@param mob number Entity handle
---@param zone number Zone index
---@param netId number Network ID
local function handleIdleBehavior(mob, zone, netId)
    if isMobIdle(mob) then
        makeWander(mob, zone, netId)
    end
end

--- Main mob control loop - called while we own the mob
---@param mob number Entity handle
---@param zone number Zone index
---@param mobConfig table Mob type configuration
---@param netId number Network ID
local function runMobControlLoop(mob, zone, mobConfig, netId)
    while NetworkGetEntityOwner(mob) == cache.playerId do
        local nearPlayer, nearPlayerDistance = getClosestPlayerToMob(mob)
        local tickDelay = 5000

        ensureMovementClipset(mob, mobConfig, netId)

        if nearPlayerDistance <= mobConfig.visualRange then
            handleChasePlayer(mob, nearPlayer, nearPlayerDistance, mobConfig, netId)
            tickDelay = 1000
        else
            handleIdleBehavior(mob, zone, netId)
            tickDelay = 2000
        end

        Citizen.Wait(tickDelay)
    end
end

RegisterNetEvent("nts_mobs:client:control_mob")
AddEventHandler("nts_mobs:client:control_mob", function(zone, netId, mobType)
    local mob = NetworkGetEntityFromNetworkId(netId)
    local mobConfig = Config.Mob.MobType[mobType]

    Debug(zone, zoneMob[zone] and true or false, netId, mob)

    if not DoesEntityExist(mob) then return end

    configureMobBehavior(mob)
    runMobControlLoop(mob, zone, mobConfig, netId)
    TriggerServerEvent("nts_mobs:lostOwnership", zone, netId)
end)