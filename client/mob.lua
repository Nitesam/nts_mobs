
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

        local self_net_id = PlayerId()
        local tickCounter = 0

        while thread_helper_initialized == zone do
            tickCounter = tickCounter + 1

            local allPeds = GetGamePool('CPed')
            local self_coords = cache.coords or GetEntityCoords(cache.ped)
            for i = 1, #allPeds do
                local ped = allPeds[i]
                if IsPedAPlayer(ped) then goto continue end
                if not NetworkGetEntityIsNetworked(ped) then goto continue end

                local netId = NetworkGetNetworkIdFromEntity(ped)
                if not netId or netId == 0 then goto continue end
                if knownMobs[netId] == false then goto continue end
                if CONTROLLED_MOBS[netId] then goto continue end

                local ped_owner = NetworkGetEntityOwner(ped)
                if ped_owner ~= self_net_id then goto continue end

                local pedCoords = GetEntityCoords(ped)
                local distSq = (self_coords.x - pedCoords.x)^2 + (self_coords.y - pedCoords.y)^2 + (self_coords.z - pedCoords.z)^2
                if distSq > maxDistSq then goto continue end

                local mobType = Entity(ped).state.mobType
                if mobType then
                    TriggerEvent("nts_mobs:client:internal_add_mob", zone, netId, mobType)
                    Debug("^1[Thread Helper]^7 Added mob with netId " .. netId .. " owned by self.")
                    knownMobs[netId] = true
                else
                    knownMobs[netId] = false
                end

                ::continue::
            end
            if tickCounter >= 20 then
                tickCounter = 0
                for netId, _ in pairs(knownMobs) do
                    if not NetworkDoesEntityExistWithNetworkId(netId) then
                        knownMobs[netId] = nil
                    end
                end
            end

            Citizen.Wait(250)
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

            local minHeight = findThicknessBasedOnArea(v.pos, v.forcedMinHeight)
            --for i = 1, #v.pos do v.pos[i] = vec3(v.pos[i].x, v.pos[i].y, v.pos[i].z + (minHeight/2)) end

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
                end,
                onExit = function(self)
                    zoneMob[k].inside = false
                    TriggerServerEvent("nts_mobs:server:playerExitZone", k)
                    Debug("Exited zone " .. k)
                    thread_helper_initialized = 0
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
    local points = GetRandomPoints(zone, Config.Mob.Zone[zone].pos, count)
    if Config.Debug then ThreadMarkingPoints(points) end
    return points
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
