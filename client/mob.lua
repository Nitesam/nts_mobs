
local init, ready = false, false
zoneMob = {}

local function findThicknessBasedOnArea(points)
    if not next(points) then return 1.0 end

    local highestZ, lowestZ = math.maxinteger, -math.maxinteger

    for i = 1, #points do
        if points[i].z > highestZ then
            highestZ = points[i].z
        end
        if points[i].z < lowestZ then
            lowestZ = points[i].z
        end
    end

    return math.clamp((highestZ - lowestZ) + 1.0, 5.0, 1000.0)
end

local function initialize()
    if not init then
        init = true

        for k, v in pairs(Config.Mob.Zone) do
            Debug("Initializing zone " .. k .. "...")

            zoneMob[k] = {}
            zoneMob[k].inside = false
            zoneMob[k].poly = lib.zones.poly({
                points = v.pos,
                thickness = findThicknessBasedOnArea(v.pos),
                debug = v.debug,
                inside = function() end,
                onEnter = function(self)
                    zoneMob[k].inside = true
                    TriggerServerEvent("nts_mobs:server:playerEnterZone", k)
                    Debug("Entered zone " .. k)
                end,
                onExit = function(self)
                    zoneMob[k].inside = false
                    TriggerServerEvent("nts_mobs:server:playerExitZone", k)
                    Debug("Exited zone " .. k)
                end
            })
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

-- Check if already loaded on resource start
Citizen.CreateThread(function()
    Wait(500) -- Wait for framework detection
    if not IsPlayerLoaded() then return end
    initialize()
end)
