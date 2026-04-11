local QBCore = exports['qb-core']:GetCoreObject()
local CurrentHeat = 0
local IsJammed = false

local function Notify(message, msgType)
    if Config.Notifications.UseQBCoreNotify then
        QBCore.Functions.Notify(message, msgType or 'primary')
    else
        TriggerEvent('chat:addMessage', { args = { '^2Resistance', message } })
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('resistance:server:requestState', Config.Security.ServerEventToken)
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function()
    TriggerServerEvent('resistance:server:requestState', Config.Security.ServerEventToken)
end)

RegisterNetEvent('resistance:client:notify', function(message, msgType)
    Notify(message, msgType)
end)

RegisterNetEvent('resistance:client:updateHeat', function(value, label)
    CurrentHeat = value
    Notify(('مستوى الخطر: %s (%s)'):format(value, label), 'error')
end)

RegisterNetEvent('resistance:client:policeMissileBlip', function(coords, duration)
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.job or not Resistance.IsPolice(playerData.job.name) then
        return
    end

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Missile.PoliceBlipSprite)
    SetBlipColour(blip, Config.Missile.PoliceBlipColor)
    SetBlipScale(blip, 1.2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('إطلاق صاروخي مرصود')
    EndTextCommandSetBlipName(blip)

    SetTimeout((duration or Config.Missile.PoliceBlipDurationSeconds) * 1000, function()
        RemoveBlip(blip)
    end)
end)

RegisterNetEvent('resistance:client:jamPoliceRadio', function(duration)
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.job or not Resistance.IsPolice(playerData.job.name) then
        return
    end

    if IsJammed then return end
    IsJammed = true
    Notify('تعرضت أجهزة الشرطة للتشويش مؤقتًا.', 'error')

    -- Placeholder: integrate your radio script (pma-voice / mumble / etc)
    SetTimeout((duration or Config.Missile.JamDurationSeconds) * 1000, function()
        IsJammed = false
        Notify('انتهى التشويش وعادت أجهزة الشرطة للعمل.', 'success')
    end)
end)

RegisterNetEvent('resistance:client:missileImpact', function(missileType, coords)
    if missileType == 'explosive' then
        AddExplosion(coords.x, coords.y, coords.z, 29, 6.0, true, false, 1.0)
    elseif missileType == 'smoke' then
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('exp_grd_flare', coords.x, coords.y, coords.z + 0.2, 0.0, 0.0, 0.0, 3.0, false, false, false)
    elseif missileType == 'jamming' then
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('ent_sht_electrical_box', coords.x, coords.y, coords.z + 0.2, 0.0, 0.0, 0.0, 1.5, false, false, false)
    end
end)

RegisterNetEvent('resistance:client:playCountdown', function(seconds)
    for i = seconds, 1, -1 do
        PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)
        Notify(('إطلاق الصاروخ بعد %s ثانية'):format(i), 'primary')
        Wait(1000)
    end
end)

RegisterNetEvent('resistance:client:cinematic', function(payload)
    SendNUIMessage({
        action = 'cinematic',
        show = true,
        data = payload,
    })

    SetNuiFocus(false, false)
    Wait((payload.duration or Config.Cinematic.DurationSeconds) * 1000)
    SendNUIMessage({ action = 'cinematic', show = false })
end)

RegisterCommand('resheat', function()
    Notify(('Heat: %s'):format(CurrentHeat), 'primary')
end, false)
