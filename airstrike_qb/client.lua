local QBCore = exports['qb-core']:GetCoreObject()

local activePending = nil
local currentTarget = nil
local laserMode = false
local droneMode = false
local uiOpen = false

local function nui(action, payload)
    SendNUIMessage({ action = action, text = payload and payload.text, coords = payload and payload.coords })
end

local function setUi(state)
    uiOpen = state
    SetNuiFocus(state, state)
    nui(state and 'open' or 'close')
end

local function loadModel(model)
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    return true
end

local function rayCastFromCamera(maxDist)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local dir = vector3(
        -math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))),
        math.sin(math.rad(camRot.x))
    )
    local dest = camCoord + (dir * maxDist)
    local handle = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, -1, PlayerPedId(), 0)
    local _, hit, endCoords = GetShapeTestResult(handle)
    return hit == 1, endCoords
end

local function createMarkerBlip(coords, ms)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 161)
    SetBlipColour(blip, 1)
    SetBlipScale(blip, 1.1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('منطقة ضربة صاروخية')
    EndTextCommandSetBlipName(blip)
    SetTimeout(ms, function()
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end

local function warningSiren(durationMs)
    CreateThread(function()
        local finishAt = GetGameTimer() + durationMs
        while GetGameTimer() < finishAt do
            PlaySoundFrontend(-1, 'Bed', 'WastedSounds', true)
            Wait(1000)
        end
    end)
end

local function requestStrike(coords, strikeType)
    QBCore.Functions.TriggerCallback('airstrike:server:canCall', function(ok, reason)
        if not ok then
            nui('status', { text = reason or 'تم رفض الطلب' })
            return QBCore.Functions.Notify(reason or 'تم رفض الطلب', 'error')
        end

        TriggerServerEvent('airstrike:server:requestStrike', {
            coords = { x = coords.x, y = coords.y, z = coords.z },
            strikeType = strikeType,
        })
        nui('status', { text = 'تم إرسال الطلب إلى القيادة...' })
    end, {
        coords = { x = coords.x, y = coords.y, z = coords.z },
        strikeType = strikeType,
    })
end

if Config.UseCommand then
    RegisterCommand(Config.CommandName, function()
        setUi(true)
        nui('status', { text = 'اختر النوع ثم حدد الهدف عبر الزر.' })
        nui('target', { coords = currentTarget })
    end)

    RegisterCommand(Config.CancelCommandName, function()
        if activePending then
            TriggerServerEvent('airstrike:server:cancelStrike', activePending)
            activePending = nil
            nui('status', { text = 'تم إرسال إلغاء الضربة.' })
        else
            QBCore.Functions.Notify('لا توجد ضربة قيد الانتظار', 'error')
        end
    end)
end

RegisterNUICallback('pick_target', function(_, cb)
    local hit, coords = rayCastFromCamera(Config.TargetMaxDistance)
    if hit then
        currentTarget = coords
        nui('target', { coords = coords })
        nui('status', { text = 'تم قفل الهدف بنجاح.' })
    else
        nui('status', { text = 'لم يتم العثور على نقطة صالحة أمامك.' })
    end
    cb('ok')
end)

RegisterNUICallback('fire', function(data, cb)
    if not currentTarget then
        nui('status', { text = 'حدد الهدف أولاً.' })
        cb('no_target')
        return
    end

    requestStrike(currentTarget, data.strikeType or 'single')
    cb('ok')
end)

RegisterNUICallback('cancel_pending', function(_, cb)
    if activePending then
        TriggerServerEvent('airstrike:server:cancelStrike', activePending)
        activePending = nil
        nui('status', { text = 'تم إلغاء الضربة المعلقة.' })
    else
        nui('status', { text = 'لا توجد ضربة معلقة حالياً.' })
    end
    cb('ok')
end)

RegisterNUICallback('toggle_laser', function(_, cb)
    laserMode = not laserMode
    nui('status', { text = laserMode and 'تم تفعيل مؤشر الليزر.' or 'تم إيقاف مؤشر الليزر.' })
    cb('ok')
end)

RegisterNUICallback('toggle_drone', function(_, cb)
    droneMode = not droneMode
    nui('status', { text = droneMode and 'تم تفعيل وضع الدرون.' or 'تم إيقاف وضع الدرون.' })
    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    setUi(false)
    cb('ok')
end)

RegisterNetEvent('airstrike:client:pendingStrike', function(data)
    activePending = data.token
    local finishAt = GetGameTimer() + (data.countdown * 1000)

    CreateThread(function()
        while activePending == data.token and GetGameTimer() < finishAt do
            Wait(500)
            local left = math.ceil((finishAt - GetGameTimer()) / 1000)
            nui('status', { text = ('العد التنازلي: %s ثواني'):format(left) })
        end
        if activePending == data.token then
            activePending = nil
        end
    end)
end)

RegisterNetEvent('airstrike:client:globalWarning', function(data)
    QBCore.Functions.Notify(data.text or 'تحذير: صاروخ وارد', 'error', 6000)
    warningSiren(4500)
    if data.coords then
        createMarkerBlip(data.coords, data.pingDuration or 8000)
    end
end)

local function applyImpactEffects(epicenter, explosionCfg)
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local dist = #(pedCoords - epicenter)

    if dist < 50.0 then
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', explosionCfg.cameraShake or 1.0)
    end

    if dist < 18.0 and not IsPedRagdoll(ped) then
        SetPedToRagdoll(ped, 1200, 1200, 0, true, true, false)
    end

    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 and dist < 35.0 then
        local forward = GetEntityForwardVector(veh)
        ApplyForceToEntity(veh, 1, forward.x * explosionCfg.vehiclePushForce, forward.y * explosionCfg.vehiclePushForce, 12.0, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
    end
end

local function spawnFireZone(center, durationMs, tickMs, radius)
    CreateThread(function()
        local finishAt = GetGameTimer() + durationMs
        while GetGameTimer() < finishAt do
            Wait(tickMs)
            local angle = math.random() * math.pi * 2.0
            local r = math.random() * radius
            local pos = vector3(center.x + math.cos(angle) * r, center.y + math.sin(angle) * r, center.z)
            StartScriptFire(pos.x, pos.y, pos.z, 25, true)
        end
    end)
end

local function satelliteCamera(target)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(cam, target.x, target.y, target.z + 160.0)
    PointCamAtCoord(cam, target.x, target.y, target.z)
    SetCamFov(cam, 38.0)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    return cam
end

local function missileFollowCamera(entity, target)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)

    CreateThread(function()
        while DoesEntityExist(entity) do
            Wait(0)
            local pos = GetEntityCoords(entity)
            SetCamCoord(cam, pos.x + 9.0, pos.y + 9.0, pos.z + 4.0)
            PointCamAtCoord(cam, target.x, target.y, target.z)
        end

        Wait(550)
        RenderScriptCams(false, true, 700, true, true)
        DestroyCam(cam, false)
    end)
end

local function missileDrop(target, missileCfg, explosionCfg)
    local satCam = satelliteCamera(target)
    Wait(650)

    local model = missileCfg.model
    if not loadModel(model) then
        if satCam then
            RenderScriptCams(false, true, 400, true, true)
            DestroyCam(satCam, false)
        end
        AddExplosion(target.x, target.y, target.z, explosionCfg.explosionType, explosionCfg.damageScale, true, false, 1.0)
        return
    end

    local spawn = vector3(target.x, target.y, target.z + missileCfg.startHeight)
    local missile = CreateObjectNoOffset(model, spawn.x, spawn.y, spawn.z, true, false, false)
    SetEntityCollision(missile, false, false)
    SetEntityHeading(missile, GetRandomFloatInRange(0.0, 359.0))

    if satCam then
        RenderScriptCams(false, true, 350, true, true)
        DestroyCam(satCam, false)
    end

    missileFollowCamera(missile, target)

    local speed = missileCfg.minSpeed
    local impact = false

    while DoesEntityExist(missile) and not impact do
        Wait(0)
        local pos = GetEntityCoords(missile)
        local dir = (target - pos)
        local distance = #dir

        if distance < 2.2 then
            impact = true
        else
            local nDir = dir / distance
            speed = math.min(speed + missileCfg.acceleration, missileCfg.maxSpeed)
            SetEntityCoordsNoOffset(missile, pos.x + nDir.x * (speed * 0.01), pos.y + nDir.y * (speed * 0.01), pos.z + nDir.z * (speed * 0.01), true, true, true)
            if speed > missileCfg.maxSpeed * 0.7 then
                PlaySoundFromCoord(-1, '5_Second_Timer', pos.x, pos.y, pos.z, 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', false, 0, false)
            end
        end
    end

    if DoesEntityExist(missile) then
        DeleteEntity(missile)
    end

    AddExplosion(target.x, target.y, target.z, explosionCfg.explosionType, explosionCfg.damageScale, true, false, 2.0)
    StartParticleFxNonLoopedAtCoord('exp_grd_bzgas_smoke', target.x, target.y, target.z, 0.0, 0.0, 0.0, 1.2, false, false, false)
    applyImpactEffects(target, explosionCfg)
end

local function computeImpact(base, strikeCfg, idx, total, randomOffset)
    local out = vector3(base.x, base.y, base.z)

    if strikeCfg.linePattern then
        local span = strikeCfg.spreadRadius
        local start = -span * 0.5
        local step = total > 1 and (span / (total - 1)) or 0.0
        out = vector3(base.x + start + (idx - 1) * step, base.y, base.z)
    elseif strikeCfg.spreadRadius > 0.0 then
        local angle = math.random() * math.pi * 2.0
        local rad = math.random() * strikeCfg.spreadRadius
        out = vector3(base.x + math.cos(angle) * rad, base.y + math.sin(angle) * rad, base.z)
    end

    if randomOffset and randomOffset > 0.0 then
        out = vector3(out.x + GetRandomFloatInRange(-randomOffset, randomOffset), out.y + GetRandomFloatInRange(-randomOffset, randomOffset), out.z)
    end

    return out
end

RegisterNetEvent('airstrike:client:startStrike', function(data)
    if data.antiIntercepted then
        QBCore.Functions.Notify('تم اعتراض الصاروخ بواسطة الدفاع الجوي', 'error')
        return
    end

    local strikeCfg = data.config
    local missiles = strikeCfg.missiles or 1

    CreateThread(function()
        for i = 1, missiles do
            local impactPos = computeImpact(data.coords, strikeCfg, i, missiles, data.randomOffset)
            missileDrop(impactPos, data.missile, data.explosion)
            spawnFireZone(impactPos, data.fireZoneDuration, data.fireZoneTick, data.fireZoneRadius)
            Wait(strikeCfg.delayBetween or 200)
        end

        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        if #(pcoords - data.coords) < Config.AlertRadius then
            DisplayRadar(false)
            SetTimecycleModifier('scanline_cam_cheap')
            Wait(data.jamDuration or 5000)
            SetTimecycleModifier('default')
            DisplayRadar(true)
        end
    end)
end)

CreateThread(function()
    while true do
        Wait(0)

        if laserMode then
            local hit, coords = rayCastFromCamera(Config.Laser.maxDistance)
            if hit then
                DrawMarker(28, coords.x, coords.y, coords.z + 0.02, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.08, 0.08, 0.08, 255, 0, 0, 210, false, true, 2, false, nil, nil, false)
                if IsControlJustReleased(0, 191) then
                    requestStrike(coords, 'single')
                    laserMode = false
                end
            end
        end

        if droneMode then
            local hit, coords = rayCastFromCamera(1200.0)
            if hit then
                DrawMarker(6, coords.x, coords.y, coords.z + 0.1, 0.0, 0.0, 0.0, 90.0, 0.0, 0.0, 1.2, 1.2, 1.2, 80, 130, 255, 210, false, true, 2, false, nil, nil, false)
                if IsControlJustReleased(0, 25) then
                    currentTarget = coords
                    nui('target', { coords = currentTarget })
                    nui('status', { text = 'تم قفل الهدف عبر الدرون.' })
                end
                if currentTarget then
                    DrawMarker(1, currentTarget.x, currentTarget.y, currentTarget.z + 0.2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.4, 1.4, 1.0, 255, 50, 50, 160, false, true, 2, false, nil, nil, false)
                    if IsControlJustReleased(0, 191) then
                        requestStrike(currentTarget, 'cluster')
                        droneMode = false
                    end
                end
            end
        end
    end
end)
