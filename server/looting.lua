math.randomseed(os.time()) 
-- random seed per fare in modo che ad ogni riavvio il server abbiamo un pattern diverso di loot generato, francamente
-- credo basti solo al server startup, non oltre, passo il tempo corrente come seed per essere univoco ad ogni riavvio.

function GenerateLootForMob(mobConfig) -- dovrebbe essere O(log n) però verificherò in successivametne 
    local max_loot = mobConfig.max_loot or 0
    if max_loot <= 0 then return {} end
    
    local loot_config = mobConfig.loot
    if not loot_config then return {} end

    local possible_loot = {}
    local total_weight = 0
    local count = 0
    
    for item, details in pairs(loot_config) do
        count = count + 1
        possible_loot[count] = {
            item = item,
            weight = details.weight,
            min = details.min,
            max = details.max
        }
        total_weight = total_weight + details.weight
    end

    if count == 0 then return {} end

    local loot_table = {}
    local selected = 0
    
    while selected < max_loot and count > 0 do
        local rand = math.random() * total_weight
        local cumulative = 0
        
        for i = 1, count do
            local loot = possible_loot[i]
            cumulative = cumulative + loot.weight
            
            if rand <= cumulative then
                selected = selected + 1
                loot_table[selected] = {
                    item = loot.item,
                    quantity = math.random(loot.min, loot.max)
                }

                total_weight = total_weight - loot.weight
                possible_loot[i] = possible_loot[count]
                possible_loot[count] = nil
                count = count - 1
                break
            end
        end
    end

    return loot_table
end

RegisterNetEvent("nts_mobs:server:open_loot_menu", function(netId, zone)
    if not zone then
        print("User ".. GetPlayerName(source) .." tried to open loot menu without zone specified.")
        return
    end

    if ZONE_TAB.zones[zone] == nil then
        print("User ".. GetPlayerName(source) .." tried to open loot menu for invalid zone: " .. tostring(zone))
        return
    end

    local mob = NetworkGetEntityFromNetworkId(netId)
    if not mob or not DoesEntityExist(mob) then
        Debug("Mob entity does not exist for netId: " .. tostring(netId))
        return
    end

    if #(GetEntityCoords(source) - GetEntityCoords(mob)) > 5.0 then
        Debug("Player too far from mob to loot. NetId: " .. tostring(netId))
        return
    end

    --if not ZONE
    local mobData = ZONE_TAB.zones[zone].entities[netId]
    if not mobData then
        Debug("Mob with netId " .. tostring(netId) .. " is invalid.")
        return
    end

    local stashId = zone .. "-mob-".. netId
    exports.core_inventory:openInventory(source, stashId, 'stash', nil, nil, true, nil, true)
end)

--[[
    source number? server id of the player, can be nil

    inventoryname string   inventory name like :  'content-'.. citizenid / identifier:gsub(':','') or 'stash-'.. citizenid / identifier:gsub(':','')

    inventorytype

    string

    inventory type like 'content' or 'stash'

    x

    number

    position in pixel on the screen horizontally

    y

    number

    position in pixel on the screen vertically

    open

    boolean

    define if the inventory should be open (display) or just preopen (load)

    content

    table

    the default content of the inventory (return the content of the inventory if its already exist)

    discoverItem

    boolean

    if true, the content of the inventory will need to be discovered (item will be hide / shadow)
]]