local uiOpen = false
local launcherModel = `chernobog` -- change if your model name changes

local function notify(msg)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, false)
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

RegisterCommand("mlrs", function()
    local ok = isDriverInLauncher()
    if not ok then
        notify("~r~You must be driver of the launcher vehicle.")
        return
    end

    uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "open" })
end, false)

RegisterNUICallback("close", function(_, cb)
    uiOpen = false
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

    if rockets < 1 then rockets = 1 end
    if rockets > 24 then rockets = 24 end
    if spread < 1.0 then spread = 1.0 end
    if spread > 120.0 then spread = 120.0 end
    if delayMs < 150 then delayMs = 150 end
    if delayMs > 2000 then delayMs = 2000 end

    moveLauncherToward(veh, wp)

    local launchPos = GetEntityCoords(veh)
    local netVeh = VehToNet(veh)

    TriggerServerEvent("himars:requestStrike", {
        target = { x = wp.x, y = wp.y, z = wp.z },
        launch = { x = launchPos.x, y = launchPos.y, z = launchPos.z },
        rockets = rockets,
        spread = spread,
        delayMs = delayMs,
        netVeh = netVeh
    })

    notify("~g~Strike requested.")
    cb({ ok = true })
end)

RegisterNetEvent("himars:launchFx", function(netVeh)
    local veh = NetToVeh(netVeh)
    if veh == 0 or not DoesEntityExist(veh) then
        return
    end

    UseParticleFxAssetNextCall("core")
    StartNetworkedParticleFxNonLoopedOnEntity(
        "exp_grd_flare",
        veh,
        0.0, -3.2, 1.9,
        -90.0, 0.0, 0.0,
        1.0, false, false, false
    )
    PlaySoundFromEntity(-1, "FIRE", veh, "DLC_HEIST_BIOLAB_PREP_HACKING_SOUNDS", false, 0)
end)

RegisterNetEvent("himars:impactFx", function(x, y, z)
    AddExplosion(x, y, z, 29, 12.0, true, false, 1.2)
end)
