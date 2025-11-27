Framework = nil
FrameworkType = nil

local function DetectFramework()
    if FrameworkType then return end

    local qbSuccess, qbCore = pcall(function()
        return exports['qb-core']:GetCoreObject()
    end)

    if qbSuccess and qbCore then
        Framework = qbCore
        FrameworkType = 'qb'
        print('^2[nts_mobs]^0 Framework detected: ^5QB-Core^0')
        return
    end

    local esxSuccess, esx = pcall(function()
        return exports['es_extended']:getSharedObject()
    end)

    if esxSuccess and esx then
        Framework = esx
        FrameworkType = 'esx'
        print('^2[nts_mobs]^0 Framework detected: ^5ESX^0')
        return
    end

    if not IsDuplicityVersion() then
        TriggerEvent('esx:getSharedObject', function(obj) 
            if obj then
                Framework = obj
                FrameworkType = 'esx'
                print('^2[nts_mobs]^0 Framework detected: ^5ESX (legacy)^0')
            end
        end)
    end

    if not FrameworkType then
        print('^1[nts_mobs]^0 No framework detected! Running in standalone mode.')
        FrameworkType = 'standalone'
    end
end

CreateThread(function()
    Wait(100)
    DetectFramework()
end)

function GetFramework()
    if not FrameworkType then DetectFramework() end
    return Framework, FrameworkType
end

function Notify(message, type)
    if IsDuplicityVersion() then return end

    local fw, fwType = GetFramework()

    if fwType == 'qb' and fw then
        fw.Functions.Notify(message, type or 'primary')
    elseif fwType == 'esx' and fw then
        local esxType = type == 'primary' and 'info' or type
        fw.ShowNotification(message, esxType)
    else
        BeginTextCommandThefeedPost('STRING')
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end

function IsPlayerLoaded()
    local fw, fwType = GetFramework()

    if fwType == 'qb' and fw then
        local playerData = fw.Functions.GetPlayerData()
        return playerData and playerData.citizenid ~= nil
    elseif fwType == 'esx' and fw then
        local playerData = fw.GetPlayerData()
        return playerData and playerData.identifier ~= nil
    end

    return true
end


if IsDuplicityVersion() then
    function GetPlayer(source)
        local fw, fwType = GetFramework()

        if fwType == 'qb' and fw then
            return fw.Functions.GetPlayer(source)
        elseif fwType == 'esx' and fw then
            return fw.GetPlayerFromId(source)
        end

        return nil
    end

    function GetPlayerIdentifier(source)
        local fw, fwType = GetFramework()

        if fwType == 'qb' and fw then
            local player = fw.Functions.GetPlayer(source)
            return player and player.PlayerData.citizenid
        elseif fwType == 'esx' and fw then
            local player = fw.GetPlayerFromId(source)
            return player and player.identifier
        end

        return nil
    end

    function AddItem(source, item, count)
        local fw, fwType = GetFramework()

        if fwType == 'qb' and fw then
            local player = fw.Functions.GetPlayer(source)
            if player then
                return player.Functions.AddItem(item, count)
            end
        elseif fwType == 'esx' and fw then
            local player = fw.GetPlayerFromId(source)
            if player then
                player.addInventoryItem(item, count)
                return true
            end
        end

        return false
    end

    function RemoveItem(source, item, count)
        local fw, fwType = GetFramework()

        if fwType == 'qb' and fw then
            local player = fw.Functions.GetPlayer(source)
            if player then
                return player.Functions.RemoveItem(item, count)
            end
        elseif fwType == 'esx' and fw then
            local player = fw.GetPlayerFromId(source)
            if player then
                player.removeInventoryItem(item, count)
                return true
            end
        end

        return false
    end

    function GetItemCount(source, item)
        local fw, fwType = GetFramework()

        if fwType == 'qb' and fw then
            local player = fw.Functions.GetPlayer(source)
            if player then
                local itemData = player.Functions.GetItemByName(item)
                return itemData and itemData.amount or 0
            end
        elseif fwType == 'esx' and fw then
            local player = fw.GetPlayerFromId(source)
            if player then
                local itemData = player.getInventoryItem(item)
                return itemData and itemData.count or 0
            end
        end

        return 0
    end
end
