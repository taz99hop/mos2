local launcherModel = `chernobog` -- change if your vehicle model changes
local missileModel = `w_lr_himars` -- missile object model

local activeCountdown = nil

local function notify(msg)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
end

local function drawText2D(text, x, y, scale)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(255, 220, 120, 220)
    SetTextOutline()
    SetTextCentre(true)
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function isDriverInLauncher()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        return false, nil
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if GetEntityModel(veh) ~= launcherModel then
        return false, nil
    end

    if GetPedInVehicleSeat(veh, -1) ~= ped then
        return false, nil
    end

    return true, veh
end

local function getWaypointCoords()
    local blip = GetFirstBlipInfoId(8) -- waypoint
    if not DoesBlipExist(blip) then
        return nil
    end

    local c = GetBlipInfoIdCoord(blip)
    return vector3(c.x, c.y, c.z)
end

local function moveLauncherToward(veh, target)
    local ped = PlayerPedId()
    local cur = GetEntityCoords(veh)
    local dist = #(cur - target)

    if dist < 120.0 then
        return
    end

    local heading = GetHeadingFromVector_2d(target.x - cur.x, target.y - cur.y)
    local standOff = 180.0
    local tx = target.x - math.cos(math.rad(heading)) * standOff
    local ty = target.y - math.sin(math.rad(heading)) * standOff
    local tz = target.z

    TaskVehicleDriveToCoordLongrange(ped, veh, tx, ty, tz, 18.0, 447, 20.0)
    notify("~y~Launcher moving to firing position...")
    local timeout = GetGameTimer() + 20000

    while GetGameTimer() < timeout do
        Wait(500)
        if #(GetEntityCoords(veh) - vector3(tx, ty, tz)) < 25.0 then
            break
        end
    end

    ClearPedTasks(ped)
end

local function ensureModel(hash)
    if HasModelLoaded(hash) then
        return true
    end

    RequestModel(hash)
    local timeout = GetGameTimer() + 7000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(25)
    end

    return HasModelLoaded(hash)
end

local function bezierPoint(t, p0, p1, p2)
    local omt = 1.0 - t
    local x = omt * omt * p0.x + 2.0 * omt * t * p1.x + t * t * p2.x
    local y = omt * omt * p0.y + 2.0 * omt * t * p1.y + t * t * p2.y
    local z = omt * omt * p0.z + 2.0 * omt * t * p1.z + t * t * p2.z
    return vector3(x, y, z)
end

local function launchMissileArc(launch, target, flightMs)
    if not ensureModel(missileModel) then
        AddExplosion(target.x, target.y, target.z, 29, 10.0, true, false, 1.0)
        return
    end

    local startPos = vector3(launch.x, launch.y, launch.z + 2.0)
    local endPos = vector3(target.x, target.y, target.z + 0.3)
    local dist2d = #(vector2(startPos.x, startPos.y) - vector2(endPos.x, endPos.y))
    local arcHeight = math.max(80.0, dist2d * 0.18)
    local mid = vector3(
        (startPos.x + endPos.x) * 0.5,
        (startPos.y + endPos.y) * 0.5,
        math.max(startPos.z, endPos.z) + arcHeight
    )

    local obj = CreateObjectNoOffset(missileModel, startPos.x, startPos.y, startPos.z, true, true, false)
    if obj == 0 then
        AddExplosion(target.x, target.y, target.z, 29, 10.0, true, false, 1.0)
        return
    end

    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, false, false)
    SetEntityInvincible(obj, true)

    UseParticleFxAssetNextCall("core")
    local trail = StartParticleFxLoopedOnEntity("ent_amb_smoke_foundry", obj, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.8, false, false, false)

    local startTime = GetGameTimer()
    local endTime = startTime + flightMs
    local prev = startPos

    while GetGameTimer() < endTime do
        local now = GetGameTimer()
        local t = (now - startTime) / flightMs
        if t > 1.0 then t = 1.0 end

        local pos = bezierPoint(t, startPos, mid, endPos)
        SetEntityCoordsNoOffset(obj, pos.x, pos.y, pos.z, false, false, false)

        local dir = pos - prev
        if #(dir) > 0.001 then
            local heading = GetHeadingFromVector_2d(dir.x, dir.y)
            local pitch = math.deg(math.atan2(dir.z, math.sqrt(dir.x * dir.x + dir.y * dir.y)))
            SetEntityRotation(obj, pitch, 0.0, heading, 2, true)
        end

        prev = pos
        Wait(0)
    end

    if trail ~= 0 then
        StopParticleFxLooped(trail, 0)
    end

    DeleteEntity(obj)
    AddExplosion(endPos.x, endPos.y, endPos.z, 29, 12.0, true, false, 1.2)
end

RegisterCommand("mlrs", function()
    local ok = isDriverInLauncher()
    if not ok then
        notify("~r~You must be driver of the launcher vehicle.")
        return
    end

    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
end, false)

RegisterNUICallback("close", function(_, cb)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

RegisterNUICallback("fire_waypoint", function(data, cb)
    local ok, veh = isDriverInLauncher()
    if not ok then
        cb({ ok = false, err = "not_in_launcher" })
        return
    end

    local wp = getWaypointCoords()
    if not wp then
        notify("~r~Set a waypoint first on the map.")
        cb({ ok = false, err = "no_waypoint" })
        return
    end

    local rockets = tonumber(data.rockets) or 6
    local spread = tonumber(data.spread) or 35.0
    local delayMs = tonumber(data.delay) or 500

    rockets = math.max(1, math.min(rockets, 24))
    spread = math.max(1.0, math.min(spread, 120.0))
    delayMs = math.max(150, math.min(delayMs, 2000))

    moveLauncherToward(veh, wp)

    local launchPos = GetEntityCoords(veh)
    TriggerServerEvent("himars:requestStrike", {
        target = { x = wp.x, y = wp.y, z = wp.z },
        launch = { x = launchPos.x, y = launchPos.y, z = launchPos.z },
        rockets = rockets,
        spread = spread,
        delayMs = delayMs
    })

    notify("~g~Strike requested.")
    cb({ ok = true })
end)

RegisterNetEvent("himars:notify", function(msg)
    notify(msg)
end)

RegisterNetEvent("himars:startCountdown", function(target, countdownMs)
    activeCountdown = {
        target = vector3(target.x + 0.0, target.y + 0.0, target.z + 0.0),
        endsAt = GetGameTimer() + (countdownMs or 5000)
    }

    CreateThread(function()
        while activeCountdown and GetGameTimer() < activeCountdown.endsAt do
            local leftMs = activeCountdown.endsAt - GetGameTimer()
            local sec = math.ceil(leftMs / 1000)

            DrawMarker(
                1,
                activeCountdown.target.x, activeCountdown.target.y, activeCountdown.target.z + 0.3,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                12.0, 12.0, 1.4,
                255, 120, 0, 120,
                false, true, 2, false, nil, nil, false
            )
            drawText2D(("ARTILLERY IMPACT IN: ~y~%ss"):format(sec), 0.5, 0.08, 0.45)
            Wait(0)
        end

        activeCountdown = nil
    end)
end)

RegisterNetEvent("himars:spawnMissile", function(payload)
    if type(payload) ~= "table" or not payload.launch or not payload.target then
        return
    end

    CreateThread(function()
        launchMissileArc(payload.launch, payload.target, payload.flightMs or 5000)
    end)
end)
