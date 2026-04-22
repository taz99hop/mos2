local QBCore = exports['qb-core']:GetCoreObject()

local siloState = {
    isOpen = false,
    isRisen = false,
    isArmed = false,
    isBusy = false,
    missileType = 'tactical',
    target = nil,
    launchReady = false,
    sequence = 'idle'
}

local entities = {
    hatch = nil,
    platform = nil,
    arm = nil,
    missile = nil
}

local monitorCam = nil
local nuiOpen = false
local activeTrails = {}

local function logDebug(...)
    if Config.Debug then
        print('[silo]', ...)
    end
end

local function loadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
    end
end

local function loadPtfx(dict)
    if not HasNamedPtfxAssetLoaded(dict) then
        RequestNamedPtfxAsset(dict)
        while not HasNamedPtfxAssetLoaded(dict) do
            Wait(0)
        end
    end
end

local function ensureEntities()
    if DoesEntityExist(entities.hatch) and DoesEntityExist(entities.platform) and DoesEntityExist(entities.arm) then
        return
    end

    loadModel(Config.Models.hatch)
    loadModel(Config.Models.elevator)
    loadModel(Config.Models.arm)

    local c = Config.Base.hatchCenter
    entities.hatch = CreateObject(Config.Models.hatch, c.x, c.y, c.z, false, false, false)
    entities.platform = CreateObject(Config.Models.elevator, c.x, c.y, Config.Base.elevatorBottomZ, false, false, false)
    entities.arm = CreateObject(Config.Models.arm, c.x, c.y, Config.Base.elevatorBottomZ + Config.Base.armPivotOffset.z, false, false, false)

    SetEntityHeading(entities.hatch, Config.Base.heading)
    SetEntityHeading(entities.platform, Config.Base.heading)
    SetEntityHeading(entities.arm, Config.Base.heading)

    FreezeEntityPosition(entities.hatch, true)
    FreezeEntityPosition(entities.platform, true)
    FreezeEntityPosition(entities.arm, true)

    SetEntityCollision(entities.hatch, true, true)
    SetEntityCollision(entities.platform, true, true)
    SetEntityCollision(entities.arm, true, true)

    SetEntityCoordsNoOffset(entities.platform, c.x, c.y, Config.Base.elevatorBottomZ, false, false, false)
    SetEntityCoordsNoOffset(entities.arm, c.x + Config.Base.armPivotOffset.x, c.y + Config.Base.armPivotOffset.y, Config.Base.elevatorBottomZ + Config.Base.armPivotOffset.z, false, false, false)

    SetEntityRotation(entities.arm, Config.Sequence.armStartPitch, 0.0, Config.Base.heading, 2, true)
end

local function playControlRoomAudio(name)
    local c = Config.Base.hatchCenter
    PlaySoundFromCoord(-1, name, c.x, c.y, c.z, 'DLC_BTL_Hacker_Drone_HUD_Scene_Sounds', false, 0, false)
end

local function openMonitorCam(enable)
    if enable then
        if monitorCam then return end
        monitorCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        SetCamCoord(monitorCam, Config.Base.camera.pos.x, Config.Base.camera.pos.y, Config.Base.camera.pos.z)
        SetCamRot(monitorCam, Config.Base.camera.rot.x, Config.Base.camera.rot.y, Config.Base.camera.rot.z, 2)
        SetCamFov(monitorCam, Config.Base.camera.fov)
        SetCamActive(monitorCam, true)
        RenderScriptCams(true, true, 600, true, true)
    else
        if monitorCam then
            RenderScriptCams(false, true, 600, true, true)
            DestroyCam(monitorCam, false)
            monitorCam = nil
        end
    end
end

local function heavyRise(entity, fromZ, toZ, durationMs)
    local start = GetGameTimer()
    while true do
        local elapsed = GetGameTimer() - start
        local t = math.min(1.0, elapsed / durationMs)
        local eased = t * t * (3.0 - 2.0 * t)
        local z = fromZ + ((toZ - fromZ) * eased)
        local pos = GetEntityCoords(entity)
        SetEntityCoordsNoOffset(entity, pos.x, pos.y, z, false, false, false)
        if t >= 1.0 then break end
        Wait(Config.Sequence.heavyTickMs)
    end
end

local function heavyPitch(entity, fromPitch, toPitch, durationMs)
    local start = GetGameTimer()
    while true do
        local elapsed = GetGameTimer() - start
        local t = math.min(1.0, elapsed / durationMs)
        local eased = t * t * (3.0 - 2.0 * t)
        local pitch = fromPitch + ((toPitch - fromPitch) * eased)
        local _, _, yaw = table.unpack(GetEntityRotation(entity, 2))
        SetEntityRotation(entity, pitch, 0.0, yaw, 2, true)
        if t >= 1.0 then break end
        Wait(Config.Sequence.heavyTickMs)
    end
end

local function attachMissile(missileType)
    local spec = Config.Missiles[missileType]
    if not spec then return end

    if DoesEntityExist(entities.missile) then
        DeleteEntity(entities.missile)
        entities.missile = nil
    end

    loadModel(spec.prop)
    local armPos = GetEntityCoords(entities.arm)
    entities.missile = CreateObject(spec.prop, armPos.x, armPos.y, armPos.z + 0.5, true, true, true)
    SetEntityCollision(entities.missile, false, false)
    FreezeEntityPosition(entities.missile, true)

    AttachEntityToEntity(
        entities.missile,
        entities.arm,
        -1,
        spec.offset.x,
        spec.offset.y,
        spec.offset.z,
        spec.rot.x,
        spec.rot.y,
        spec.rot.z,
        false,
        false,
        false,
        false,
        2,
        true
    )
end

local function syncStateUI()
    SendNUIMessage({
        action = 'state',
        payload = siloState
    })
end

local function setNuiFocusState(state)
    nuiOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = 'toggle', show = state, payload = siloState })
    openMonitorCam(state)
end

RegisterNUICallback('close', function(_, cb)
    setNuiFocusState(false)
    cb('ok')
end)

RegisterNUICallback('setTarget', function(data, cb)
    TriggerServerEvent('underground_silo:server:setTarget', data)
    cb('ok')
end)

RegisterNUICallback('setMissileType', function(data, cb)
    TriggerServerEvent('underground_silo:server:setMissileType', data.type)
    cb('ok')
end)

RegisterNUICallback('stepAction', function(data, cb)
    TriggerServerEvent('underground_silo:server:step', data.action)
    cb('ok')
end)

local function localEMP()
    StartScreenEffect('DrugsTrevorClownsFight', Config.EmpDurationMs, false)
    SetArtificialLightsState(true)
    Wait(Config.EmpDurationMs)
    SetArtificialLightsState(false)
    StopScreenEffect('DrugsTrevorClownsFight')
end

local function spawnChemicalCloud(pos)
    loadPtfx('core')
    local untilTime = GetGameTimer() + Config.ChemicalDurationMs
    CreateThread(function()
        while GetGameTimer() < untilTime do
            UseParticleFxAssetNextCall('core')
            StartParticleFxNonLoopedAtCoord('exp_grd_grenade_smoke', pos.x, pos.y, pos.z + 0.3, 0.0, 0.0, 0.0, 2.0, false, false, false)
            for _, player in ipairs(GetActivePlayers()) do
                local ped = GetPlayerPed(player)
                local pPos = GetEntityCoords(ped)
                local distance = #(pPos - pos)
                if distance <= 26.0 then
                    ApplyDamageToPed(ped, 4, false)
                end
            end
            Wait(1200)
        end
    end)
end

local function runGlobalNukeFx(pos)
    for i = 1, 2 do
        StartScreenEffect('SwitchHUDIn', 1400, false)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.7)
        Wait(1200)
    end

    loadPtfx('core')
    for h = 1, 22 do
        local z = pos.z + (h * 4.2)
        local scale = 2.0 + (h * 0.35)
        UseParticleFxAssetNextCall('core')
        StartParticleFxNonLoopedAtCoord('exp_grd_flare', pos.x, pos.y, z, -90.0, 0.0, 0.0, scale, false, false, false)
        Wait(100)
    end
end

local function launchMissileThread(data)
    local missileType = data.type
    local spec = Config.Missiles[missileType]
    if not spec then return end

    if not DoesEntityExist(entities.missile) then
        attachMissile(missileType)
    end

    DetachEntity(entities.missile, true, true)
    FreezeEntityPosition(entities.missile, false)
    SetEntityCollision(entities.missile, true, true)

    local target = vec3(data.target.x + 0.0, data.target.y + 0.0, data.target.z + 0.0)
    local startPos = GetEntityCoords(entities.missile)
    local dir = (target - startPos)
    local dist = #dir
    if dist <= 0.1 then return end
    dir = dir / dist

    loadPtfx(spec.flightTrail)
    UseParticleFxAssetNextCall(spec.flightTrail)
    local trail = StartParticleFxLoopedOnEntity(spec.flightFx, entities.missile, 0.0, -0.2, 0.0, 0.0, 0.0, 0.0, 1.6, false, false, false)
    activeTrails[#activeTrails + 1] = trail

    local traveled = 0.0
    while traveled < dist do
        local delta = spec.speed * 0.02
        traveled = traveled + delta
        local nextPos = startPos + (dir * traveled)

        SetEntityCoordsNoOffset(entities.missile, nextPos.x, nextPos.y, nextPos.z, true, true, true)
        SetEntityRotation(entities.missile, -math.deg(math.asin(dir.z)), 0.0, GetHeadingFromVector_2d(dir.x, dir.y), 2, true)

        if HasEntityCollidedWithAnything(entities.missile) then
            break
        end

        Wait(20)
    end

    local impactPos = GetEntityCoords(entities.missile)

    AddExplosion(impactPos.x, impactPos.y, impactPos.z, 59, spec.baseDamage + 0.0, true, false, spec.impactRadius)

    if missileType == 'emp' then
        localEMP()
    elseif missileType == 'chemical' then
        spawnChemicalCloud(impactPos)
    elseif missileType == 'nuclear' then
        runGlobalNukeFx(impactPos)
    end

    if trail and DoesParticleFxLoopedExist(trail) then
        StopParticleFxLooped(trail, 0)
    end

    if DoesEntityExist(entities.missile) then
        DeleteEntity(entities.missile)
        entities.missile = nil
    end
end

RegisterNetEvent('underground_silo:client:updateState', function(newState)
    siloState = newState
    syncStateUI()
end)

RegisterNetEvent('underground_silo:client:doStep', function(step, context)
    ensureEntities()

    if step == 'open_hatch' then
        playControlRoomAudio(Config.Sounds.hatchSteam)
        local base = Config.Base.hatchCenter
        local from = base.z
        local to = base.z + Config.Base.hatchOpenZOffset
        heavyRise(entities.hatch, from, to, Config.Sequence.hatchOpenMs)
    elseif step == 'raise_platform' then
        playControlRoomAudio(Config.Sounds.heavyMotor)
        local from = Config.Base.elevatorBottomZ
        local to = Config.Base.elevatorTopZ

        CreateThread(function()
            heavyRise(entities.platform, from, to, Config.Sequence.platformRiseMs)
        end)

        CreateThread(function()
            local armFrom = Config.Base.elevatorBottomZ + Config.Base.armPivotOffset.z
            local armTo = Config.Base.elevatorTopZ + Config.Base.armPivotOffset.z
            heavyRise(entities.arm, armFrom, armTo, Config.Sequence.platformRiseMs)
        end)

        Wait(Config.Sequence.platformRiseMs + 50)
        attachMissile(siloState.missileType)
    elseif step == 'arm_vertical' then
        heavyPitch(entities.arm, Config.Sequence.armStartPitch, Config.Sequence.armEndPitch, Config.Sequence.armPitchMs)
    elseif step == 'launch' then
        playControlRoomAudio(Config.Sounds.launch)
        CreateThread(function()
            launchMissileThread(context)
        end)
    elseif step == 'cleanup' then
        if DoesEntityExist(entities.missile) then DeleteEntity(entities.missile) end
        entities.missile = nil
    end
end)

RegisterCommand(Config.CommandOpenPanel, function()
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.job then return end
    if not Config.AuthorizedJobs[playerData.job.name] then
        QBCore.Functions.Notify('غير مصرح لك باستخدام منظومة الصومعة', 'error')
        return
    end

    setNuiFocusState(not nuiOpen)
    syncStateUI()
end, false)

CreateThread(function()
    ensureEntities()

    exports['qb-target']:AddBoxZone('silo_control_panel', Config.Base.controlPanel, 1.0, 0.8, {
        heading = 0,
        debugPoly = false,
        minZ = Config.Base.controlPanel.z - 1.0,
        maxZ = Config.Base.controlPanel.z + 1.0,
    }, {
        options = {
            {
                type = 'client',
                icon = 'fas fa-satellite-dish',
                label = 'لوحة تحكم الصومعة',
                action = function()
                    ExecuteCommand(Config.CommandOpenPanel)
                end
            }
        },
        distance = 2.0
    })
end)
