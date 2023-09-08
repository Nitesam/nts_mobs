local gasZone = {}

local function trovaZoneGas(k, v)
    local posizioni = {}

    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    for _, point in ipairs(v.positions) do
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end

    local numEffectsX = math.floor((maxX - minX) /  v.effects.effectsDistance)
    local numEffectsY = math.floor((maxY - minY) / v.effects.effectsDistance)

    for i = 0, numEffectsX - 1 do
        for j = 0, numEffectsY - 1 do
            local x = minX + i * v.effects.effectsDistance
            local y = minY + j * v.effects.effectsDistance
            local _, z = GetGroundZFor_3dCoord(x, y, 100.0, false)

            if isPointInPolygon(x, y, v.positions) and not isPointNearPolygonBorder(x, y, v.positions, v.effects.borderDistance) then
                if #posizioni > 0 then
                    if math.random(1, 100) < 60 then
                        table.insert(posizioni, {pos = vec3(x, y, z), index = nil})
                    end
                else
                    table.insert(posizioni, {pos = vec3(x, y, z), index = nil})
                end
            end
        end
    end

    return posizioni
end


Citizen.CreateThread(function()
    for k,v in pairs(Config.ToxicZone.Zones) do
        gasZone[k] = {}
        gasZone[k].puntiGas = trovaZoneGas(k, v)
        gasZone[k].posizioneCentrale = getCentroid(v.positions)
        gasZone[k].raggioMinimo = getMinRadius(gasZone[k].posizioneCentrale, v.positions)

        Debug(k, "Centro - " .. json.encode(gasZone[k].posizioneCentrale))

        if v.blip then
            gasZone[k].blip = AddBlipForCoord(gasZone[k].posizioneCentrale.x, gasZone[k].posizioneCentrale.y)
            SetBlipSprite(gasZone[k].blip, v.blip.sprite)
            SetBlipDisplay(gasZone[k].blip, v.blip.display)
            SetBlipScale(gasZone[k].blip, v.blip.scale)
            SetBlipColour(gasZone[k].blip, v.blip.color)
            SetBlipAsShortRange(gasZone[k].blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.name)
            EndTextCommandSetBlipName(gasZone[k].blip)
        end

        local function onEnter(self)
        end

        local function onExit(self)
            for a,b in pairs(gasZone[k].puntiGas) do
                if b.index then
                    StopParticleFxLooped(b.index, 0)
                    b.index = nil

                    Debug("Rimuovo Gas in - ", gasZone[k].puntiGas[a].pos.x, gasZone[k].puntiGas[a].pos.y, gasZone[k].puntiGas[a].pos.z)
                end
            end
        end

        local function inside(self)
            local playerCoords = GetEntityCoords(cache.ped)

            for a,b in pairs(gasZone[k].puntiGas) do
                local dPoint = #(gasZone[k].puntiGas[a].pos - playerCoords)

                if not gasZone[k].puntiGas[a].index then
                    if dPoint < Config.ToxicZone.GlobalRendering then
                        RequestNamedPtfxAsset(v.effects.particle.particleDictionary)
                        while not HasNamedPtfxAssetLoaded(v.effects.particle.particleDictionary) do
                            Citizen.Wait(1)
                        end

                        UseParticleFxAsset(v.effects.particle.particleDictionary)
                        gasZone[k].puntiGas[a].index = StartParticleFxLoopedAtCoord(v.effects.particle.particleName, gasZone[k].puntiGas[a].pos.x, gasZone[k].puntiGas[a].pos.y, gasZone[k].puntiGas[a].pos.z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)

                        SetParticleFxLoopedColour(gasZone[k].puntiGas[a].index, v.effects.particle.color[1], v.effects.particle.color[2], v.effects.particle.color[3], v.effects.particle.color[4])
                        SetParticleFxLoopedAlpha(gasZone[k].puntiGas[a].index, v.effects.particle.alpha)
                        SetParticleFxLoopedScale(gasZone[k].puntiGas[a].index, v.effects.particle.scale)

                        Debug("Gas Spawn in - ", gasZone[k].puntiGas[a].pos.x, gasZone[k].puntiGas[a].pos.y, gasZone[k].puntiGas[a].pos.z)
                    end
                else
                    if dPoint < v.effects.effectsDistance then
                        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) - v.effects.damage)
                    elseif dPoint >= Config.ToxicZone.GlobalRendering then
                        StopParticleFxLooped(gasZone[k].puntiGas[a].index, 0)
                        gasZone[k].puntiGas[a].index = nil

                        Debug("Rimuovo Gas in - ", gasZone[k].puntiGas[a].pos.x, gasZone[k].puntiGas[a].pos.y, gasZone[k].puntiGas[a].pos.z)
                    end
                end
            end

            Wait(v.effects.tickTime * 1000)
        end

        gasZone[k].poly = lib.zones.poly({
            points = v.positions,
            thickness = v.thickness,
            debug = v.debug,
            inside = inside,
            onEnter = onEnter,
            onExit = onExit
        })
    end
end)