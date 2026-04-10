local QBCore = exports['qb-core']:GetCoreObject()

local ActiveAlerts = {}

local function Debug(...)
    if Config.Debug then
        print('[qb-panicdevice]', ...)
    end
end

local function IsDispatchJob(jobName)
    return Config.DispatchJobs[jobName] == true
end

local function GetTargetResponders()
    local players = QBCore.Functions.GetQBPlayers()
    local responders = {}

    for _, player in pairs(players) do
        if player and player.PlayerData and player.PlayerData.job and IsDispatchJob(player.PlayerData.job.name) then
            responders[#responders + 1] = player.PlayerData.source
        end
    end

    return responders
end

local function BuildAlertData(src)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then
        return nil
    end

    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    return {
        id = src,
        source = src,
        citizenid = player.PlayerData.citizenid,
        fullname = (player.PlayerData.charinfo.firstname or 'Unknown') .. ' ' .. (player.PlayerData.charinfo.lastname or ''),
        reason = Config.AlertReason,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
        },
        responder = nil,
        createdAt = os.time(),
    }
end

local function CloseAlert(src, reason)
    local alert = ActiveAlerts[src]
    if not alert then
        return
    end

    ActiveAlerts[src] = nil
    TriggerClientEvent('qb-panicdevice:client:alertClosed', -1, src, reason or 'closed')
    Debug(('Alert closed for %s (%s)'):format(src, reason or 'closed'))
end

local function PushAlertUpdate(alert)
    local responders = GetTargetResponders()
    if #responders == 0 then
        return
    end

    for i = 1, #responders do
        local target = responders[i]
        TriggerClientEvent('qb-panicdevice:client:newAlert', target, alert)
    end
end

QBCore.Functions.CreateUseableItem(Config.ItemName, function(source)
    local src = source

    if ActiveAlerts[src] then
        TriggerClientEvent('QBCore:Notify', src, 'يوجد نداء طوارئ نشط بالفعل.', 'error')
        return
    end

    TriggerClientEvent('qb-panicdevice:client:startSend', src)
end)

RegisterNetEvent('qb-panicdevice:server:createAlert', function()
    local src = source

    if ActiveAlerts[src] then
        return
    end

    local alert = BuildAlertData(src)
    if not alert then
        return
    end

    ActiveAlerts[src] = alert
    PushAlertUpdate(alert)

    TriggerClientEvent('qb-panicdevice:client:alertCreated', src)
    Debug(('Alert created for %s'):format(src))
end)

RegisterNetEvent('qb-panicdevice:server:updateCoords', function(coords)
    local src = source
    local alert = ActiveAlerts[src]

    if not alert or type(coords) ~= 'table' then
        return
    end

    alert.coords = {
        x = coords.x,
        y = coords.y,
        z = coords.z,
    }

    local responders = GetTargetResponders()
    for i = 1, #responders do
        TriggerClientEvent('qb-panicdevice:client:updateAlert', responders[i], alert)
    end
end)

RegisterNetEvent('qb-panicdevice:server:acceptAlert', function(alertSource)
    local src = source
    local responder = QBCore.Functions.GetPlayer(src)
    local alert = ActiveAlerts[alertSource]

    if not responder or not alert then
        return
    end

    if not IsDispatchJob(responder.PlayerData.job.name) then
        return
    end

    if alert.responder and alert.responder ~= src then
        TriggerClientEvent('QBCore:Notify', src, 'البلاغ تم استلامه من عسكري آخر.', 'error')
        return
    end

    alert.responder = src

    local responders = GetTargetResponders()
    for i = 1, #responders do
        local target = responders[i]
        TriggerClientEvent('qb-panicdevice:client:alertAccepted', target, alertSource, src)
    end

    TriggerClientEvent('qb-panicdevice:client:beginTracking', src, alert)
end)

RegisterNetEvent('qb-panicdevice:server:cancelAlert', function(reason)
    local src = source
    CloseAlert(src, reason or 'cancelled')
end)

RegisterNetEvent('qb-panicdevice:server:forceCloseAlert', function(alertSource, reason)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)
    if not player or not IsDispatchJob(player.PlayerData.job.name) then
        return
    end

    CloseAlert(alertSource, reason or 'system')
end)

AddEventHandler('playerDropped', function()
    local src = source
    CloseAlert(src, 'disconnect')
end)
