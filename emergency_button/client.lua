local QBCore = exports['qb-core']:GetCoreObject()

local function isAllowedClientSide()
    if Config.AllowPrisoners then return true end

    local data = QBCore.Functions.GetPlayerData()
    return data and data.job and data.job.name == Config.PoliceJobName
end

local function notify(msg, nType)
    QBCore.Functions.Notify(msg, nType or 'primary')
end

local function addModelTargets()
    if not Config.TargetModels or #Config.TargetModels == 0 then return end

    exports['qb-target']:AddTargetModel(Config.TargetModels, {
        options = {
            {
                icon = 'fas fa-triangle-exclamation',
                label = 'Emergency Button',
                canInteract = function()
                    return isAllowedClientSide()
                end,
                action = function(entity)
                    local coords = GetEntityCoords(entity)
                    TriggerServerEvent('mos2:emergency:server:trigger', {
                        x = coords.x,
                        y = coords.y,
                        z = coords.z,
                    })
                end,
            }
        },
        distance = 1.8,
    })
end

local function addZoneTargets()
    if not Config.TargetZones then return end

    for _, zone in ipairs(Config.TargetZones) do
        exports['qb-target']:AddBoxZone(zone.name, zone.coords, zone.length, zone.width, {
            name = zone.name,
            heading = zone.heading,
            debugPoly = Config.Debug,
            minZ = zone.minZ,
            maxZ = zone.maxZ,
        }, {
            options = {
                {
                    icon = 'fas fa-triangle-exclamation',
                    label = 'Emergency Button',
                    canInteract = function()
                        return isAllowedClientSide()
                    end,
                    action = function()
                        TriggerServerEvent('mos2:emergency:server:trigger', {
                            x = zone.coords.x,
                            y = zone.coords.y,
                            z = zone.coords.z,
                        })
                    end,
                }
            },
            distance = 1.8,
        })
    end
end

CreateThread(function()
    addModelTargets()
    addZoneTargets()
end)

RegisterNetEvent('mos2:emergency:client:cooldown', function(secondsLeft)
    notify(('زر الطوارئ غير متاح الآن. المتبقي: %s ثانية'):format(secondsLeft), 'error')
end)

RegisterNetEvent('mos2:emergency:client:policeAlert', function(message, coords)
    notify(message, 'error')

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.Blip.Sprite)
    SetBlipColour(blip, Config.Blip.Color)
    SetBlipScale(blip, Config.Blip.Scale)
    SetBlipAsShortRange(blip, false)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.Blip.Label)
    EndTextCommandSetBlipName(blip)

    CreateThread(function()
        Wait((Config.Blip.TimeoutSeconds or 60) * 1000)
        RemoveBlip(blip)
    end)
end)

RegisterNetEvent('mos2:emergency:client:startAlarm', function(coords)
    local durationMs = (Config.Alarm.DurationSeconds or 20) * 1000
    local intervalMs = Config.Alarm.SoundIntervalMs or 1500
    local endAt = GetGameTimer() + durationMs

    if Config.Alarm.UseInteractSound then
        TriggerServerEvent('InteractSound_SV:PlayWithinDistance', 120.0, Config.Alarm.InteractSoundFile, Config.Alarm.InteractSoundVolume)
        return
    end

    CreateThread(function()
        while GetGameTimer() < endAt do
            PlaySoundFromCoord(
                -1,
                Config.Alarm.NativeSound.name,
                coords.x,
                coords.y,
                coords.z,
                Config.Alarm.NativeSound.set,
                false,
                30,
                false
            )
            Wait(intervalMs)
        end
    end)
end)
