local QBCore = exports['qb-core']:GetCoreObject()

local uiOpen = false
local selectedTarget = nil
local currentCooldown = 0

local function notify(msg, ntype)
    QBCore.Functions.Notify(msg, ntype or 'primary')
end

local function isInLaunchTruck()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return false, nil
    end

    local vehicle = GetVehiclePedIsIn(ped, false)
    if GetEntityModel(vehicle) ~= Config.TruckModel then
        return false, nil
    end

    if Config.RequireDriverSeat and GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return false, vehicle
    end

    return true, vehicle
end

local function setNui(state)
    uiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({
        action = state and 'open' or 'close',
        cooldown = currentCooldown,
        defaultMissiles = Config.DefaultMissileCount,
        minMissiles = Config.MinMissiles,
        maxMissiles = Config.MaxMissiles,
        hasTarget = selectedTarget ~= nil
    })
end

local function chooseTargetFromWaypoint()
    local waypointBlip = GetFirstBlipInfoId(8)
    if not DoesBlipExist(waypointBlip) then
        notify('حدد Waypoint على الخريطة أولاً.', 'error')
        return nil
    end

    local coord = GetBlipInfoIdCoord(waypointBlip)
    local ok, vehicle = isInLaunchTruck()
    if not ok then
        notify('يجب أن تكون داخل شاحنة الإطلاق.', 'error')
        return nil
    end

    local vCoord = GetEntityCoords(vehicle)
    local dist = #(coord - vCoord)

    if dist > Config.MaxLaunchRange then
        notify(('الهدف بعيد جداً. الحد الأقصى %.0f متر.'):format(Config.MaxLaunchRange), 'error')
        return nil
    end

    selectedTarget = coord
    notify(('تم تثبيت الهدف على مسافة %.0f متر.'):format(dist), 'success')

    SendNUIMessage({
        action = 'targetSelected',
        hasTarget = true,
        x = coord.x,
        y = coord.y,
        z = coord.z,
        distance = math.floor(dist)
    })

    return coord
end

RegisterNUICallback('close', function(_, cb)
    setNui(false)
    cb(true)
end)

RegisterNUICallback('pickTarget', function(_, cb)
    chooseTargetFromWaypoint()
    cb(true)
end)

RegisterNUICallback('launch', function(data, cb)
    local missiles = tonumber(data.missiles) or Config.DefaultMissileCount
    local target = selectedTarget

    if not target then
        notify('حدد الهدف أولاً.', 'error')
        cb(false)
        return
    end

    missiles = math.max(Config.MinMissiles, math.min(Config.MaxMissiles, missiles))

    TriggerServerEvent('mos2_missile:server:requestLaunch', {
        target = {
            x = target.x + 0.0,
            y = target.y + 0.0,
            z = target.z + 0.0
        },
        missiles = missiles
    })

    cb(true)
end)

RegisterNetEvent('mos2_missile:client:launchApproved', function(payload)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then
        return
    end

    local startPos = GetOffsetFromEntityInWorldCoords(vehicle, -1.2, -4.8, 2.3)

    for i = 1, payload.missiles do
        local impact = vector3(
            payload.target.x + (math.random() * 2.0 - 1.0) * payload.spread,
            payload.target.y + (math.random() * 2.0 - 1.0) * payload.spread,
            payload.target.z
        )

        local missileHash = Config.MissileModel
        RequestModel(missileHash)
        while not HasModelLoaded(missileHash) do
            Wait(0)
        end

        local projPos = vector3(startPos.x, startPos.y, startPos.z + (i * 0.15))
        local rocket = CreateObjectNoOffset(missileHash, projPos.x, projPos.y, projPos.z, true, true, false)

        local timeMs = 1200 + i * 80
        local dir = impact - projPos
        local vel = dir / (timeMs / 1000.0)

        SetEntityVelocity(rocket, vel.x, vel.y, vel.z)

        if Config.ScreenShake then
            ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', Config.ScreenShakeStrength)
        end

        PlaySoundFromCoord(-1, Config.LaunchSound, projPos.x, projPos.y, projPos.z, Config.LaunchSoundSet, true, 0, false)

        CreateThread(function()
            Wait(timeMs)
            if DoesEntityExist(rocket) then
                local pos = GetEntityCoords(rocket)
                AddExplosion(pos.x, pos.y, pos.z, 29, 20.0, true, false, 1.0)
                DeleteEntity(rocket)
            else
                AddExplosion(impact.x, impact.y, impact.z, 29, 20.0, true, false, 1.0)
            end
        end)

        Wait(payload.delay)
    end

    if Config.ScreenShake then
        Wait(Config.ScreenShakeDurationMs)
        StopGameplayCamShaking(true)
    end

    selectedTarget = nil
    SendNUIMessage({ action = 'clearTarget' })
    notify('تم إطلاق الرشقة الصاروخية بنجاح.', 'success')
end)

RegisterNetEvent('mos2_missile:client:setCooldown', function(seconds)
    currentCooldown = seconds
    SendNUIMessage({ action = 'cooldown', cooldown = seconds })
end)

CreateThread(function()
    while true do
        Wait(1000)
        if currentCooldown > 0 then
            currentCooldown = currentCooldown - 1
            if currentCooldown < 0 then currentCooldown = 0 end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local inTruck = isInLaunchTruck()
        if inTruck then
            local key = 0
            if Config.OpenUiKey == 'F6' then key = 167 end
            if Config.OpenUiKey == 'F7' then key = 168 end
            if Config.OpenUiKey == 'F5' then key = 166 end

            if key ~= 0 and IsControlJustReleased(0, key) then
                setNui(not uiOpen)
            end

            if not uiOpen then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName(('~INPUT_SELECT_CHARACTER_FRANKLIN~ نظام HIMARS - افتح اللوحة (%s)'):format(Config.OpenUiKey))
                EndTextCommandDisplayHelp(0, false, false, -1)
            end
        elseif uiOpen then
            setNui(false)
        else
            Wait(500)
        end
    end
end)
