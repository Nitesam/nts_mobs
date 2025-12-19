
local init, ready = false, false
zoneMob = {}

local function findThicknessBasedOnArea(points, forcedMinHeight)
    if not next(points) then return 1.0 end

    local highestZ, lowestZ = -math.maxinteger, math.maxinteger

    for i = 1, #points do
        if points[i].z > highestZ then
            highestZ = points[i].z
        end
        if points[i].z < lowestZ then
            lowestZ = points[i].z
        end
    end
    if forcedMinHeight and highestZ < forcedMinHeight then highestZ = forcedMinHeight end

    return math.clamp((highestZ - lowestZ) + 1.0, 1.0, 1000.0) + 3.0
end

local function makeBlipForZone(index, zoneConfig)
    if not zoneConfig.blip then return end

    local blip = AddBlipForCoord(zoneConfig.pos[1].x, zoneConfig.pos[1].y, zoneConfig.pos[1].z)
    SetBlipSprite(blip, 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(zoneConfig.name or ("Mob Zone " .. tostring(index)))
    EndTextCommandSetBlipName(blip)
    return blip
end

local thread_helper_initialized = 0
local knownMobs = {}

local function init_thread_helper(zone)
    if thread_helper_initialized ~= 0 then return end
    thread_helper_initialized = zone
    knownMobs = {}

    Citizen.CreateThread(function()
        print("Starting thread helper for zone " .. zone)
        local maxDistSq <const> = 150.0 * 150.0
        local RETRY_INTERVAL <const> = 1000

        local self_net_id = PlayerId()
        local tickCounter = 0
        local currentTime = GetGameTimer()

        while thread_helper_initialized == zone do
            tickCounter = tickCounter + 1
            currentTime = GetGameTimer()

            local allPeds = GetGamePool('CPed')
            local self_coords = cache.coords or GetEntityCoords(cache.ped)
            for i = 1, #allPeds do
                local ped = allPeds[i]
                if IsPedAPlayer(ped) then goto continue end
                if not NetworkGetEntityIsNetworked(ped) then goto continue end

                local netId = NetworkGetNetworkIdFromEntity(ped)
                if not netId or netId == 0 then goto continue end
                if knownMobs[netId] == true then goto continue end
                if CONTROLLED_MOBS[netId] then goto continue end

                local knownData = knownMobs[netId]
                if type(knownData) == "number" and (currentTime - knownData) < RETRY_INTERVAL then
                    goto continue
                end

                local ped_owner = NetworkGetEntityOwner(ped)
                if ped_owner ~= self_net_id then goto continue end
                NetworkRequestControlOfEntity(ped)

                local pedCoords = GetEntityCoords(ped)
                local distSq = (self_coords.x - pedCoords.x)^2 + (self_coords.y - pedCoords.y)^2 + (self_coords.z - pedCoords.z)^2
                if distSq > maxDistSq then goto continue end

                local mobType = Entity(ped).state.mobType
                if mobType then
                    TriggerEvent("nts_mobs:client:internal_add_mob", zone, netId, mobType)
                    knownMobs[netId] = nil
                else
                    knownMobs[netId] = currentTime
                end

                ::continue::
            end
            if tickCounter >= 40 then
                tickCounter = 0
                for netId, data in pairs(knownMobs) do
                    if not NetworkDoesEntityExistWithNetworkId(netId) then
                        knownMobs[netId] = nil
                    end
                end
            end

            Citizen.Wait(100)
        end

        knownMobs = {}
        print("Exiting thread helper for zone " .. zone)
    end)
end


local function initialize()
    if not init then
        init = true

        for k, v in pairs(Config.Mob.Zone) do
            Debug("Initializing zone " .. k .. "...")

            local minHeight = findThicknessBasedOnArea(v.pos, v.forcedMinHeight) * 2
            --for i = 1, #v.pos do v.pos[i] = vec3(v.pos[i].x, v.pos[i].y, v.pos[i].z + (minHeight/2)) end

            local models_of_zone = (function()
                local models = {}
                for mobType, mobData in pairs(Config.Mob.MobType) do models[#models + 1] = mobData.ped end
                return models
            end)()

            zoneMob[k] = {}
            zoneMob[k].inside = false
            zoneMob[k].poly = lib.zones.poly({
                points = v.pos,
                thickness = minHeight,
                debug = v.debug,
                inside = function() end,
                onEnter = function(self)
                    zoneMob[k].inside = true
                    TriggerServerEvent("nts_mobs:server:playerEnterZone", k)
                    Debug("Entered zone " .. k)

                    init_thread_helper(k)
                    AddModelsToLooting(models_of_zone, k)
                end,
                onExit = function(self)
                    zoneMob[k].inside = false
                    TriggerServerEvent("nts_mobs:server:playerExitZone", k)
                    Debug("Exited zone " .. k)
                    thread_helper_initialized = 0
                    RemoveModelsFromLooting(models_of_zone)
                end
            })

            if v.debug then
                zoneMob[k].blip = makeBlipForZone(k, v)
            end
        end

        for k, v in pairs(Config.Mob.MobType) do
            RequestAnimSet(v.movClipset)
            Wait(10)
        end

        ready = true
    end
end

lib.callback.register("nts_mobs:client:request_random_points", function(zone, count)
    while not ready do Wait(10) end
    return GetRandomPoints(zone, Config.Mob.Zone[zone].pos, count)
end)

if Config.Debug then
    RegisterCommand("movClipset", function (source, args, raw)
        RequestAnimSet(args[1])
        Wait(500)
        SetPedMovementClipset(cache.ped, args[1], 1.0)
    end, false)

    RegisterCommand("checkZoneMob", function (source, args, raw)
        for k, v in pairs(zoneMob) do
            print(k, v.active)
        end
    end, false)
end

-- QB-Core player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    initialize()
end)

-- ESX player loaded
RegisterNetEvent('esx:playerLoaded', function()
    initialize()
end)

Citizen.CreateThread(function()
    Wait(500)
    if not IsPlayerLoaded() then return end
    initialize()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k, v in pairs(zoneMob) do
        if v.poly then
            v.poly:remove()
        end
        if v.blip then
            RemoveBlip(v.blip)
        end
    end
end)
if Config.Debug then
    RegisterCommand("print_status_target", function()
        local target = Target(50.0)

        if not target then
            print("No target")
            return
        end

        local netId = NetworkGetNetworkIdFromEntity(target)
        if CONTROLLED_MOBS[netId] then
            print("Target is controlled mob with netId " .. netId)
        else
            print("Target is NOT a controlled mob. NetId: " .. netId)
        end

        if knownMobs[netId] == true then
            print("Target is known mob (true) with netId " .. netId)
        elseif knownMobs[netId] == false then
            print("Target is known mob marked FALSE (ignored) with netId " .. netId)
        else
            print("Target is NOT in knownMobs at all. NetId: " .. netId)
        end

        local owner = NetworkGetEntityOwner(target)
        print("Target owner: " .. tostring(owner) .. ", self: " .. tostring(PlayerId()))
        print("Has statebag mobType: " .. tostring(Entity(target).state.mobType))
        print("Is networked: " .. tostring(NetworkGetEntityIsNetworked(target)))
        print("Is player ped: " .. tostring(IsPedAPlayer(target)))

        local self_coords = cache.coords or GetEntityCoords(cache.ped)
        local pedCoords = GetEntityCoords(target)
        local distSq = (self_coords.x - pedCoords.x)^2 + (self_coords.y - pedCoords.y)^2 + (self_coords.z - pedCoords.z)^2
        print("Distance squared: " .. tostring(distSq) .. " (max: 22500)")

        print("Thread helper initialized for zone: " .. tostring(thread_helper_initialized))

        for k, v in pairs(zoneMob) do
            if v.inside then
                print("Currently INSIDE zone: " .. tostring(k))
            end
        end
    end, false)
end