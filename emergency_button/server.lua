local QBCore = exports['qb-core']:GetCoreObject()

local lastTriggerAt = 0

local function isPolice(player)
    return player and player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == Config.PoliceJobName
end

local function lockDoors()
    if not Config.DoorsToLock then return end

    for _, doorId in ipairs(Config.DoorsToLock) do
        if GetResourceState('qb-doorlock') == 'started' then
            if exports['qb-doorlock'] and exports['qb-doorlock'].updateState then
                exports['qb-doorlock']:updateState(doorId, true)
            else
                TriggerEvent('qb-doorlock:server:updateState', nil, doorId, true, false, false, true, true)
                TriggerEvent('qb-doorlock:server:updateState', doorId, true)
            end
        end
    end
end

local function notifyPolice(message, coords)
    local players = QBCore.Functions.GetQBPlayers()

    for _, player in pairs(players) do
        if isPolice(player) then
            TriggerClientEvent('mos2:emergency:client:policeAlert', player.PlayerData.source, message, coords)
        end
    end
end

RegisterNetEvent('mos2:emergency:server:trigger', function(coords)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return end

    local allowed = Config.AllowPrisoners or isPolice(player)
    if not allowed then
        TriggerClientEvent('QBCore:Notify', src, 'غير مصرح لك باستخدام هذا الزر', 'error')
        return
    end

    local now = os.time()
    local secondsSince = now - lastTriggerAt
    if secondsSince < Config.CooldownSeconds then
        local left = Config.CooldownSeconds - secondsSince
        TriggerClientEvent('mos2:emergency:client:cooldown', src, left)
        return
    end

    lastTriggerAt = now

    if type(coords) ~= 'table' or not coords.x or not coords.y or not coords.z then
        local ped = GetPlayerPed(src)
        local pCoords = GetEntityCoords(ped)
        coords = { x = pCoords.x, y = pCoords.y, z = pCoords.z }
    end

    lockDoors()
    notifyPolice(Config.AlertMessage, coords)

    TriggerClientEvent('mos2:emergency:client:startAlarm', -1, coords)
end)
