if not Config.Debug then return end

-- ============================================
-- ESP DEBUG SYSTEM
-- ============================================

local ESP = {
    entities = {},      -- { [handler] = { entity, color, label } }
    enabled = true,
    count = 0
}

local ESP_COLORS = {
    default = { r = 255, g = 255, b = 255, a = 200 },
    enemy = { r = 255, g = 0, b = 0, a = 200 },
    friendly = { r = 0, g = 255, b = 0, a = 200 },
    neutral = { r = 255, g = 255, b = 0, a = 200 },
    dead = { r = 128, g = 128, b = 128, a = 150 }
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function GetEntityScreenPosition(entity)
    local coords = GetEntityCoords(entity)
    local onScreen, screenX, screenY = World3dToScreen2d(coords.x, coords.y, coords.z - 1.0)
    return onScreen, screenX, screenY, coords
end

local function GetEntityDimensions(entity)
    local min, max = GetModelDimensions(GetEntityModel(entity))
    return {
        width = max.x - min.x,
        height = max.z - min.z,
        depth = max.y - min.y
    }
end

local function DrawESPBox(entity, color, label)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local entityCoords = GetEntityCoords(entity)
    local distance = #(playerCoords - entityCoords)
    
    local scale = math.max(0.1, 1.0 - (distance / 500.0))

    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    
    local heading = GetEntityHeading(entity)
    local headingRad = math.rad(heading)
    local cos, sin = math.cos(headingRad), math.sin(headingRad)
    
    local halfWidth = ((max.x - min.x) / 2) * 1.1
    local halfDepth = ((max.y - min.y) / 2) * 1.1
    
    local zBottom = entityCoords.z + min.z
    local zTop = entityCoords.z + max.z
    
    -- 8 corners
    local corners = {
        -- Bottom
        vector3(entityCoords.x + cos * halfWidth - sin * halfDepth, entityCoords.y + sin * halfWidth + cos * halfDepth, zBottom),
        vector3(entityCoords.x - cos * halfWidth - sin * halfDepth, entityCoords.y - sin * halfWidth + cos * halfDepth, zBottom),
        vector3(entityCoords.x - cos * halfWidth + sin * halfDepth, entityCoords.y - sin * halfWidth - cos * halfDepth, zBottom),
        vector3(entityCoords.x + cos * halfWidth + sin * halfDepth, entityCoords.y + sin * halfWidth - cos * halfDepth, zBottom),
        -- Top
        vector3(entityCoords.x + cos * halfWidth - sin * halfDepth, entityCoords.y + sin * halfWidth + cos * halfDepth, zTop),
        vector3(entityCoords.x - cos * halfWidth - sin * halfDepth, entityCoords.y - sin * halfWidth + cos * halfDepth, zTop),
        vector3(entityCoords.x - cos * halfWidth + sin * halfDepth, entityCoords.y - sin * halfWidth - cos * halfDepth, zTop),
        vector3(entityCoords.x + cos * halfWidth + sin * halfDepth, entityCoords.y + sin * halfWidth - cos * halfDepth, zTop),
    }
    
    local r, g, b, a = color.r, color.g, color.b, color.a
    
    -- Bottom face
    DrawLine(corners[1].x, corners[1].y, corners[1].z, corners[2].x, corners[2].y, corners[2].z, r, g, b, a)
    DrawLine(corners[2].x, corners[2].y, corners[2].z, corners[3].x, corners[3].y, corners[3].z, r, g, b, a)
    DrawLine(corners[3].x, corners[3].y, corners[3].z, corners[4].x, corners[4].y, corners[4].z, r, g, b, a)
    DrawLine(corners[4].x, corners[4].y, corners[4].z, corners[1].x, corners[1].y, corners[1].z, r, g, b, a)
    
    -- Top face
    DrawLine(corners[5].x, corners[5].y, corners[5].z, corners[6].x, corners[6].y, corners[6].z, r, g, b, a)
    DrawLine(corners[6].x, corners[6].y, corners[6].z, corners[7].x, corners[7].y, corners[7].z, r, g, b, a)
    DrawLine(corners[7].x, corners[7].y, corners[7].z, corners[8].x, corners[8].y, corners[8].z, r, g, b, a)
    DrawLine(corners[8].x, corners[8].y, corners[8].z, corners[5].x, corners[5].y, corners[5].z, r, g, b, a)
    
    -- Vertical lines
    DrawLine(corners[1].x, corners[1].y, corners[1].z, corners[5].x, corners[5].y, corners[5].z, r, g, b, a)
    DrawLine(corners[2].x, corners[2].y, corners[2].z, corners[6].x, corners[6].y, corners[6].z, r, g, b, a)
    DrawLine(corners[3].x, corners[3].y, corners[3].z, corners[7].x, corners[7].y, corners[7].z, r, g, b, a)
    DrawLine(corners[4].x, corners[4].y, corners[4].z, corners[8].x, corners[8].y, corners[8].z, r, g, b, a)
    
    -- Label sopra il box
    local onScreen, screenX, screenY = World3dToScreen2d(entityCoords.x, entityCoords.y, zTop + 0.2)
    if onScreen then
        local textScale = math.max(0.25, 0.4 * scale)
        
        SetTextScale(textScale, textScale)
        SetTextFont(4)
        SetTextColour(r, g, b, 255)
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(label or "Entity")
        EndTextCommandDisplayText(screenX, screenY)
        
        SetTextScale(textScale * 0.8, textScale * 0.8)
        SetTextFont(4)
        SetTextColour(255, 255, 255, 200)
        SetTextOutline()
        SetTextCentre(true)
        BeginTextCommandDisplayText("STRING")
        AddTextComponentSubstringPlayerName(string.format("%.1fm", distance))
        EndTextCommandDisplayText(screenX, screenY + 0.02)
        
        if IsEntityAPed(entity) then
            local health = GetEntityHealth(entity)
            local maxHealth = GetPedMaxHealth(entity)
            local healthPct = math.floor((health / maxHealth) * 100)
            
            SetTextScale(textScale * 0.7, textScale * 0.7)
            SetTextFont(4)
            if healthPct > 50 then
                SetTextColour(0, 255, 0, 200)
            elseif healthPct > 25 then
                SetTextColour(255, 255, 0, 200)
            else
                SetTextColour(255, 0, 0, 200)
            end
            SetTextOutline()
            SetTextCentre(true)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(string.format("HP: %d%%", healthPct))
            EndTextCommandDisplayText(screenX, screenY + 0.04)
        end
    end
end

-- ============================================
-- CONTROL THREAD (Entity validation)
-- ============================================

Citizen.CreateThread(function()
    while true do
        if ESP.count > 0 then
            local toRemove = {}
            
            for handler, data in pairs(ESP.entities) do
                if not DoesEntityExist(data.entity) then
                    toRemove[#toRemove + 1] = handler
                end
            end
            
            for _, handler in ipairs(toRemove) do
                ESP.entities[handler] = nil
                ESP.count = ESP.count - 1
                Debug("^3[ESP] Entity removed (no longer exists): " .. handler .. "^7")
            end
        end
        
        Citizen.Wait(500)
    end
end)

-- ============================================
-- RENDER THREAD (Drawing)
-- ============================================

Citizen.CreateThread(function()
    while true do
        if ESP.enabled and ESP.count > 0 then
            for handler, data in pairs(ESP.entities) do
                if DoesEntityExist(data.entity) then
                    local color = data.color or ESP_COLORS.default

                    if IsEntityAPed(data.entity) and IsPedDeadOrDying(data.entity, true) then
                        color = ESP_COLORS.dead
                    end
                    
                    DrawESPBox(data.entity, color, data.label)
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(500)
        end
    end
end)

-- ============================================
-- EXPORTS
-- ============================================

--- Aggiunge un'entità all'ESP
---@param entity number Entity handle
---@param label string|nil Label da mostrare
---@param colorName string|nil Nome colore: "default", "enemy", "friendly", "neutral", "dead"
---@return boolean success
local function AddEntity(entity, label, colorName)
    if not entity or not DoesEntityExist(entity) then
        Debug("^1[ESP] AddEntity failed: entity does not exist^7")
        return false
    end
    
    local handler = entity
    
    if ESP.entities[handler] then
        Debug("^3[ESP] Entity already tracked: " .. handler .. "^7")
        return false
    end
    
    ESP.entities[handler] = {
        entity = entity,
        label = label or ("Entity " .. handler),
        color = ESP_COLORS[colorName] or ESP_COLORS.default
    }
    ESP.count = ESP.count + 1
    
    Debug("^2[ESP] Entity added: " .. handler .. " (" .. (label or "no label") .. ")^7")
    return true
end

--- Rimuove un'entità dall'ESP
---@param entity number Entity handle
---@return boolean success
local function RemoveEntity(entity)
    local handler = entity
    
    if not ESP.entities[handler] then
        Debug("^3[ESP] RemoveEntity: entity not found: " .. handler .. "^7")
        return false
    end
    
    ESP.entities[handler] = nil
    ESP.count = ESP.count - 1
    
    Debug("^2[ESP] Entity removed: " .. handler .. "^7")
    return true
end

--- Aggiunge multiple entità in bulk
---@param entities table Array di { entity, label?, colorName? }
---@return number addedCount
local function AddEntitiesBulk(entities)
    local added = 0
    for _, data in ipairs(entities) do
        if type(data) == "table" then
            if AddEntity(data.entity or data[1], data.label or data[2], data.colorName or data[3]) then
                added = added + 1
            end
        elseif type(data) == "number" then
            if AddEntity(data) then
                added = added + 1
            end
        end
    end
    Debug("^2[ESP] Bulk add: " .. added .. " entities added^7")
    return added
end

--- Svuota tutte le entità dall'ESP
---@return number removedCount
local function ClearAll()
    local removed = ESP.count
    ESP.entities = {}
    ESP.count = 0
    Debug("^2[ESP] Cleared all entities (" .. removed .. " removed)^7")
    return removed
end

--- Abilita/disabilita l'ESP
---@param enabled boolean
local function SetEnabled(enabled)
    ESP.enabled = enabled
    Debug("^2[ESP] " .. (enabled and "Enabled" or "Disabled") .. "^7")
end

--- Ottieni il numero di entità tracciate
---@return number count
local function GetCount()
    return ESP.count
end

--- Aggiorna label o colore di un'entità
---@param entity number
---@param label string|nil
---@param colorName string|nil
---@return boolean success
local function UpdateEntity(entity, label, colorName)
    local handler = entity
    
    if not ESP.entities[handler] then
        return false
    end
    
    if label then
        ESP.entities[handler].label = label
    end
    
    if colorName and ESP_COLORS[colorName] then
        ESP.entities[handler].color = ESP_COLORS[colorName]
    end
    
    return true
end

-- Registra exports
exports("ESP_AddEntity", AddEntity)
exports("ESP_RemoveEntity", RemoveEntity)
exports("ESP_AddEntitiesBulk", AddEntitiesBulk)
exports("ESP_ClearAll", ClearAll)
exports("ESP_SetEnabled", SetEnabled)
exports("ESP_GetCount", GetCount)
exports("ESP_UpdateEntity", UpdateEntity)

-- ============================================
-- DEBUG COMMANDS
-- ============================================

RegisterCommand("esp_toggle", function()
    ESP.enabled = not ESP.enabled
    print("^2[ESP] " .. (ESP.enabled and "Enabled" or "Disabled") .. "^7")
end, false)

RegisterCommand("esp_clear", function()
    ClearAll()
end, false)

RegisterCommand("esp_count", function()
    print("^2[ESP] Tracking " .. ESP.count .. " entities^7")
end, false)

RegisterCommand("esp_add_nearest", function()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local handle, ped = FindFirstPed()
    local success = true
    local added = 0
    
    repeat
        if DoesEntityExist(ped) and ped ~= playerPed then
            local dist = #(playerCoords - GetEntityCoords(ped))
            if dist < 100.0 then
                local label = "Ped " .. ped
                if IsPedDeadOrDying(ped, true) then
                    label = label .. " (Dead)"
                end
                if AddEntity(ped, label, IsPedDeadOrDying(ped, true) and "dead" or "enemy") then
                    added = added + 1
                end
            end
        end
        success, ped = FindNextPed(handle)
    until not success
    EndFindPed(handle)
    
    print("^2[ESP] Added " .. added .. " nearby peds^7")
end, false)

-- ============================================
-- GLOBAL ACCESS (per uso interno)
-- ============================================

_G.ESP = {
    Add = AddEntity,
    Remove = RemoveEntity,
    AddBulk = AddEntitiesBulk,
    Clear = ClearAll,
    SetEnabled = SetEnabled,
    GetCount = GetCount,
    Update = UpdateEntity
}

Debug("^2[ESP] Debug ESP system initialized^7")


--[[
    -- Aggiungi singola entità
    exports.nts_mobs:ESP_AddEntity(entity, "Animale", "enemy")

    -- Rimuovi entità
    exports.nts_mobs:ESP_RemoveEntity(entity)

    -- Bulk add
    exports.nts_mobs:ESP_AddEntitiesBulk({
        { entity = ped1, label = "Mob 1", colorName = "enemy" },
        { entity = ped2, label = "Mob 2", colorName = "friendly" },
        ped3 -- Solo handler, label/colore default
    })

    -- Svuota tutto
    exports.nts_mobs:ESP_ClearAll()

    -- Toggle on/off
    exports.nts_mobs:ESP_SetEnabled(true/false)

    -- Conta entità
    local count = exports.nts_mobs:ESP_GetCount()

    -- Aggiorna label/colore
    exports.nts_mobs:ESP_UpdateEntity(entity, "New Label", "neutral")
]]

RegisterCommand("kill", function()
    local ped = Target(50.0)
    if DoesEntityExist(ped) then
        SetEntityHealth(ped, 0)
    end
end, false)

RegisterNetEvent("nts_mobs:client:remove_mob", function(zone, data, deathCoords)
    local timeout = GetGameTimer() + 30000
    while timeout > GetGameTimer() do
        drawText3d({
            text = "Mob Eliminated",
            coords = vec3(deathCoords.x, deathCoords.y, deathCoords.z + 1.0),
            scale = 0.35,
            font = 4,
            color = vec4(255, 255, 255, 200),
            disableDrawRect = false,
            enableDropShadow = true,
            enableOutline = true
        })
    end
end)