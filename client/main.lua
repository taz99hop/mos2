local QBCore = exports['qb-core']:GetCoreObject()

local PendingAlerts = {}
local ActiveTracking = {}
local CurrentAcceptAlert = nil
local SendingAlert = false
local OwnAlertActive = false

local function LoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(50)
    end
end

local function CreateOrUpdateBlip(alertSource, coords, isTracked)
    local data = ActiveTracking[alertSource]
    if not data then
        data = {}
        ActiveTracking[alertSource] = data
    end

    if data.blip and DoesBlipExist(data.blip) then
        SetBlipCoords(data.blip, coords.x, coords.y, coords.z)
    else
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, Config.Blip.Sprite)
        SetBlipColour(blip, Config.Blip.Color)
        SetBlipScale(blip, Config.Blip.Scale)
        SetBlipAsShortRange(blip, false)
        if Config.Blip.Flash then
            SetBlipFlashes(blip, true)
        end
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(Config.Blip.Label)
        EndTextCommandSetBlipName(blip)
        data.blip = blip
    end

    if isTracked and data.blip then
        SetBlipRoute(data.blip, true)
        SetBlipRouteColour(data.blip, Config.Blip.RouteColor)
    end
end

local function RemoveTracking(alertSource)
    local data = ActiveTracking[alertSource]
    if not data then
        return
    end

    if data.blip and DoesBlipExist(data.blip) then
        RemoveBlip(data.blip)
    end

    ActiveTracking[alertSource] = nil
end

local function Notify(msg, msgType)
    QBCore.Functions.Notify(msg, msgType or 'primary')
end

local function PlayDispatchSound()
    if not Config.Sound.Enabled then
        return
    end

    PlaySoundFrontend(-1, Config.Sound.Name, Config.Sound.Set, true)
end

RegisterNetEvent('qb-panicdevice:client:startSend', function()
    if SendingAlert then
        return
    end

    SendingAlert = true
    local ped = PlayerPedId()

    LoadAnimDict(Config.UseAnim.Dict)
    TaskPlayAnim(ped, Config.UseAnim.Dict, Config.UseAnim.Name, 3.0, 3.0, Config.UseDurationMs, Config.UseAnim.Flag, 0.0, false, false, false)
    Notify(Config.SendingMessage, 'primary')

    Wait(Config.UseDurationMs)
    ClearPedTasks(ped)

    TriggerServerEvent('qb-panicdevice:server:createAlert')
    SendingAlert = false
end)

RegisterNetEvent('qb-panicdevice:client:alertCreated', function()
    OwnAlertActive = true
    PlayDispatchSound()
end)

RegisterNetEvent('qb-panicdevice:client:newAlert', function(alert)
    PendingAlerts[alert.source] = alert
    CurrentAcceptAlert = alert.source

    PlayDispatchSound()
    Notify(Config.NewAlertMessage, 'error')
end)

RegisterNetEvent('qb-panicdevice:client:updateAlert', function(alert)
    PendingAlerts[alert.source] = alert

    local tracking = ActiveTracking[alert.source]
    if tracking then
        local isTracked = tracking.isTracked or false
        CreateOrUpdateBlip(alert.source, alert.coords, isTracked)
    end
end)

RegisterNetEvent('qb-panicdevice:client:alertAccepted', function(alertSource, responderSource)
    local player = QBCore.Functions.GetPlayerData()

    if player and player.source ~= responderSource then
        Notify(string.format(Config.AcceptedByMessage, responderSource), 'primary')
    else
        Notify(Config.YouAcceptedMessage, 'success')
    end
end)

RegisterNetEvent('qb-panicdevice:client:beginTracking', function(alert)
    ActiveTracking[alert.source] = ActiveTracking[alert.source] or {}
    ActiveTracking[alert.source].isTracked = true
    CreateOrUpdateBlip(alert.source, alert.coords, true)
end)

RegisterNetEvent('qb-panicdevice:client:alertClosed', function(alertSource)
    PendingAlerts[alertSource] = nil
    if CurrentAcceptAlert == alertSource then
        CurrentAcceptAlert = nil
    end

    RemoveTracking(alertSource)
    Notify(Config.AlertClosedMessage, 'primary')

    if alertSource == GetPlayerServerId(PlayerId()) then
        OwnAlertActive = false
    end
end)

CreateThread(function()
    while true do
        local waitMs = 1000

        if CurrentAcceptAlert and PendingAlerts[CurrentAcceptAlert] then
            waitMs = 0
            if IsControlJustReleased(0, Config.AcceptKey) then
                TriggerServerEvent('qb-panicdevice:server:acceptAlert', CurrentAcceptAlert)
                CurrentAcceptAlert = nil
            end
        end

        Wait(waitMs)
    end
end)

CreateThread(function()
    while true do
        Wait(Config.UpdateIntervalMs)

        if OwnAlertActive then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            TriggerServerEvent('qb-panicdevice:server:updateCoords', {
                x = coords.x,
                y = coords.y,
                z = coords.z,
            })

            if Config.AutoCancelOnDeath and IsEntityDead(ped) then
                TriggerServerEvent('qb-panicdevice:server:cancelAlert', 'death')
                OwnAlertActive = false
            end
        end
    end
end)
