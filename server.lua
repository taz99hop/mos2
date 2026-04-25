local QBCore = exports['qb-core']:GetCoreObject()
local lastLaunchAt = 0

local function sendLog(src, message)
    local player = QBCore.Functions.GetPlayer(src)
    local name = player and (player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname) or ('Player ' .. src)
    local full = ('[missile] %s | %s'):format(name, message)

    print(full)

    if GetResourceState('qb-log') == 'started' then
        TriggerEvent('qb-log:server:CreateLog', 'default', 'Missile Launcher', 'orange', full)
    end
end

RegisterNetEvent('missile:server:requestLaunch', function(targetIndex)
    local src = source
    local target = Config.Targets[targetIndex]

    if not target then
        TriggerClientEvent('missile:client:denyLaunch', src, 'Target does not exist.')
        sendLog(src, 'launch denied: invalid target index')
        return
    end

    local now = os.time()
    local left = (lastLaunchAt + Config.Launch.cooldownSeconds) - now
    if left > 0 then
        TriggerClientEvent('missile:client:denyLaunch', src, ('Launcher cooldown: %ds remaining'):format(left))
        sendLog(src, ('launch denied: cooldown %ds'):format(left))
        return
    end

    local ped = GetPlayerPed(src)
    local playerCoords = GetEntityCoords(ped)
    local distance = #(playerCoords - Config.LaunchSite.coords)

    if distance > Config.LaunchSite.maxPlayerDistance then
        TriggerClientEvent('missile:client:denyLaunch', src, 'You moved too far from the launch area.')
        sendLog(src, ('launch denied: too far (%.2f)'):format(distance))
        return
    end

    lastLaunchAt = now
    TriggerClientEvent('missile:client:authorizedLaunch', src, targetIndex)
    sendLog(src, ('launch approved -> %s (%.2f, %.2f, %.2f)'):format(target.name, target.coords.x, target.coords.y, target.coords.z))
end)
