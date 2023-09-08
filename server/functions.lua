function pickRandomMob(mobs)
    local totalWeight = 0
    for mob, weight in pairs(mobs) do
        totalWeight = totalWeight + weight
    end

    local randomValue = math.random(1, totalWeight)
    local currentWeight = 0

    for mob, weight in pairs(mobs) do
        currentWeight = currentWeight + weight
        if randomValue <= currentWeight then
            return mob
        end
    end
end