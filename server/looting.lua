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