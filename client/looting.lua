local TargetOBJ = exports['ox_target']
TARGETS_LIST = {}

local function removeOptionsForTarget(netId)
    local target = TARGETS_LIST[netId]
    if not target then return end

    TargetOBJ:RemoveTargetEntity(target.ped)
end

AddStateBagChangeHandler('lootable', nil, function(bagName, key, value)
    if value == nil then return end

    local entity = GetEntityFromStateBagName(bagName)
    if not entity or not DoesEntityExist(entity) then return end

    local netId = NetworkGetNetworkIdFromEntity(entity)
    if not netId or netId == 0 then return end

    if value == false and TARGETS_LIST[netId] then
        removeOptionsForTarget(netId)
        TARGETS_LIST[netId] = nil
        Debug("Removed loot target for netId " .. netId)
        return
    end 

    TARGETS_LIST[netId] = entity

    TargetOBJ:addEntity(netId, {
        {
            icon = 'fas fa-box-open',
            label = 'Loota Mob',
            name = 'nts_mobs:loot_mob',
            distance = 2.0,
            canInteract = function(entity, distance, coords, name, bone)
                return true -- aggiungerò altri check qui con Black
            end,
            onSelect = function(data)
                print("Opening loot menu for netId " .. netId)
                TriggerEvent("nts_mobs:server:open_loot_menu", netId)
            end
        }
    })

    Debug("^2Added loot target for netId " .. netId .. "^7")
end)